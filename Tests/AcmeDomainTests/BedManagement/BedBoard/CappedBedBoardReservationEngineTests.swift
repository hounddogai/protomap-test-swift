@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCappedBedBoardReservationEngine()
        let item = BedManagement.newCappedBedBoardReservation("code-309", name: "name-579")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
