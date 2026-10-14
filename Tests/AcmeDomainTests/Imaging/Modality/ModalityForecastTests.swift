@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityForecastTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newModalityForecast("code-691", name: "name-682")
        #expect(item.status == Imaging.ModalityForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newModalityForecast("code-691", name: "name-682")
        try item.moveTo(Imaging.ModalityForecastStatus.draining)
        #expect(item.status == Imaging.ModalityForecastStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newModalityForecast("code-691", name: "name-682")
        item.status = Imaging.ModalityForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityForecastStatus.idle) }
    }
}
