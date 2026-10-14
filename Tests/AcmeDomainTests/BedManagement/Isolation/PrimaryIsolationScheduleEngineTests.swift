@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryIsolationScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPrimaryIsolationScheduleEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newPrimaryIsolationSchedule("code-883", name: "name-770")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
