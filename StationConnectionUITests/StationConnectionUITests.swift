import XCTest

/// Pruebas de interfaz: lanzan la app real en el simulador y la tocan.
///
/// La app arranca con `-uiTesting`: usa emisoras de ejemplo, almacenamiento
/// en memoria y un reproductor mudo (ver `App/UITestingSupport.swift`), así
/// las pruebas no dependen de la red ni del audio.
final class StationConnectionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    func testAllTabsOpen() {
        for tab in ["Explorar", "Dial", "Mis estaciones", "Inicio"] {
            app.tabBars.buttons[tab].tap()
            XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5), "No abrió \(tab)")
        }
    }

    func testPlayFromHomeAndSkipToTheNextStation() {
        let play = app.buttons["Reproducir La Mega"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()

        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["La Mega"].firstMatch.exists)

        miniPlayer.tap()
        let next = app.buttons["nowPlayingNext"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        XCTAssertEqual(next.label, "Emisora siguiente: Radio Activa")
        next.tap()

        XCTAssertTrue(app.staticTexts["Radio Activa"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Cerrar"].tap()
    }

    func testFavoriteAppearsInMyStations() {
        app.tabBars.buttons["Explorar"].tap()
        let heart = app.buttons["Añadir Jazz FM a favoritas"].firstMatch
        XCTAssertTrue(heart.waitForExistence(timeout: 5))
        heart.tap()

        app.tabBars.buttons["Mis estaciones"].tap()
        XCTAssertTrue(app.staticTexts["Jazz FM"].firstMatch.waitForExistence(timeout: 5))
    }

    func testSearchFiltersTheResults() {
        app.tabBars.buttons["Explorar"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("salsa")

        XCTAssertTrue(app.staticTexts["Salsa Brava"].firstMatch.waitForExistence(timeout: 5))
    }

    func testTheDialTunesAStation() {
        app.tabBars.buttons["Dial"].tap()
        let next = app.buttons["Emisora siguiente del dial"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()

        XCTAssertTrue(app.staticTexts["● EN EL AIRE"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground)
    }
}
