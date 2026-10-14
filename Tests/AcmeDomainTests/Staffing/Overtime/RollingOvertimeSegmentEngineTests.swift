@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRollingOvertimeSegmentEngine(Kit.Flags.newRegistry())
        let item = Staffing.newRollingOvertimeSegment("code-592", name: "name-840")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
