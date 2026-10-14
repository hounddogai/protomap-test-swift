@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimePlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultBatchedOvertimePlanEngine(Kit.Flags.newRegistry())
        let item = Staffing.newBatchedOvertimePlan("code-998", name: "name-320")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
