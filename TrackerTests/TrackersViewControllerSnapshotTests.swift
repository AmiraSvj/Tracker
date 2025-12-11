import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {
    
    var sut: TrackersViewController!
    
    override func setUp() {
        super.setUp()
        sut = TrackersViewController()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testTrackersViewControllerLightMode() {
        // Настраиваем контроллер для светлой темы
        sut.overrideUserInterfaceStyle = .light
        
        // Даём время на загрузку и отрисовку
        sut.loadViewIfNeeded()
        
        // Ждём завершения асинхронных операций
        let expectation = XCTestExpectation(description: "View loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Делаем скриншот
        assertSnapshot(
            matching: sut,
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .light)),
            named: "light_mode"
        )
    }
    
    func testTrackersViewControllerDarkMode() {
        // Настраиваем контроллер для тёмной темы
        sut.overrideUserInterfaceStyle = .dark
        
        // Даём время на загрузку и отрисовку
        sut.loadViewIfNeeded()
        
        // Ждём завершения асинхронных операций
        let expectation = XCTestExpectation(description: "View loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Делаем скриншот
        assertSnapshot(
            matching: sut,
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark)),
            named: "dark_mode"
        )
    }
}
