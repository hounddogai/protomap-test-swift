@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPrimaryBedBoardReservationEngine()
        let item = BedManagement.newPrimaryBedBoardReservation("code-242", name: "name-415")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
