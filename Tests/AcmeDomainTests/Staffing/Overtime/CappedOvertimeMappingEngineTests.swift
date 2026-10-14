@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedOvertimeMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCappedOvertimeMappingEngine(Kit.Flags.newRegistry())
        let item = Staffing.newCappedOvertimeMapping("code-73", name: "name-234")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
