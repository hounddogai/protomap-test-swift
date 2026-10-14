@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTieredCleaningReservationEngine()
        let item = BedManagement.newTieredCleaningReservation("code-480", name: "name-845")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
