import XCTest
@testable import StationConnection

final class RadioBrowserDirectoryTests: XCTestCase {
    private var session: URLSession!

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: configuration)
        StubURLProtocol.reset()
    }

    private func makeDirectory(servers: [String] = ["https://a.test", "https://b.test"]) -> RadioBrowserDirectory {
        RadioBrowserDirectory(
            session: session,
            servers: servers.map { URL(string: $0)! },
            maxAttempts: 2,
            timeout: 2,
            shuffle: { $0 } // orden fijo
        )
    }

    private let oneStation = #"[{"stationuuid":"00000000-0000-4000-8000-000000000001","name":"Uno","url":"https://x.com/1"}]"#

    func testSearchesAndMapsTheResponse() async throws {
        StubURLProtocol.responses["a.test"] = (200, oneStation)
        let result = try await makeDirectory().search(StationQuery(name: "uno"))
        XCTAssertEqual(result.map(\.name), ["Uno"])
        let url = try XCTUnwrap(StubURLProtocol.requests.first?.url)
        XCTAssertEqual(url.path, "/json/stations/search")
        XCTAssertTrue(url.query?.contains("name=uno") ?? false)
        XCTAssertNotNil(StubURLProtocol.requests.first?.value(forHTTPHeaderField: "User-Agent"))
    }

    func testFallsBackToAnotherMirrorOnServerErrors() async throws {
        StubURLProtocol.responses["a.test"] = (503, "")
        StubURLProtocol.responses["b.test"] = (200, oneStation)
        let result = try await makeDirectory().search(StationQuery())
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(StubURLProtocol.requests.map { $0.url?.host }, ["a.test", "b.test"])
    }

    func testFailsWhenAllMirrorsFail() async {
        StubURLProtocol.responses["a.test"] = (500, "")
        StubURLProtocol.responses["b.test"] = (200, "esto no es json")
        do {
            _ = try await makeDirectory().search(StationQuery())
            XCTFail("Debía fallar")
        } catch {
            XCTAssertEqual(error as? StationError, .directoryUnavailable)
        }
    }

    func testDoesNotRetryClientErrors() async {
        StubURLProtocol.responses["a.test"] = (404, "")
        StubURLProtocol.responses["b.test"] = (200, oneStation)
        do {
            _ = try await makeDirectory().search(StationQuery())
            XCTFail("Debía fallar")
        } catch {
            XCTAssertEqual(StubURLProtocol.requests.count, 1)
        }
    }

    func testStationsByIdKeepTheRequestedOrder() async throws {
        StubURLProtocol.responses["a.test"] = (200, """
        [{"stationuuid":"00000000-0000-4000-8000-000000000002","name":"Dos","url":"https://x.com/2"},
         {"stationuuid":"00000000-0000-4000-8000-000000000001","name":"Uno","url":"https://x.com/1"}]
        """)
        let ids = ["00000000-0000-4000-8000-000000000001", "00000000-0000-4000-8000-000000000002", "00000000-0000-4000-8000-000000000009"]
        let result = try await makeDirectory().stations(ids: ids)
        XCTAssertEqual(result.map(\.name), ["Uno", "Dos"])
    }

    func testCachesTagsAndCountries() async throws {
        StubURLProtocol.responses["a.test"] = (200, #"[{"name":"Pop","stationcount":10}]"#)
        let directory = makeDirectory()
        let first = try await directory.topTags(limit: 40)
        let second = try await directory.topTags(limit: 40)
        XCTAssertEqual(first, [Tag(name: "pop", stationCount: 10)])
        XCTAssertEqual(second, first)
        XCTAssertEqual(StubURLProtocol.requests.count, 1)
    }
}

/// Responde a las peticiones con lo configurado por host, sin red real.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [String: (Int, String)] = [:]
    nonisolated(unsafe) static var requests: [URLRequest] = []
    private static let lock = NSLock()

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        responses = [:]
        requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.requests.append(request)
        let stub = Self.responses[request.url?.host ?? ""]
        Self.lock.unlock()

        guard let stub, let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: stub.0, httpVersion: nil, headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(stub.1.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
