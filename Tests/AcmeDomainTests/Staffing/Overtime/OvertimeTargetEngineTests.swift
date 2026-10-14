@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultOvertimeTargetEngine()
        let item = Staffing.newOvertimeTarget("code-545", label: "label-102")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
