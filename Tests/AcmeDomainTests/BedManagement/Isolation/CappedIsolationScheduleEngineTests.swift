@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCappedIsolationScheduleEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCappedIsolationSchedule("code-457", name: "name-113")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
