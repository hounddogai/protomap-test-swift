@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultOvertimeSegmentEngine()
        let item = Staffing.newOvertimeSegment("code-553", name: "name-527")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
