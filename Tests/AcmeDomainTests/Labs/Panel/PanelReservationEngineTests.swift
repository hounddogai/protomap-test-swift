@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelReservationEngine()
        let item = Labs.newPanelReservation("code-935", title: "title-586")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
