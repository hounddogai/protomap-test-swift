@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRegionalOvertimeSegmentEngine(Kit.Flags.newRegistry())
        let item = Staffing.newRegionalOvertimeSegment("code-429", label: "label-820")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
