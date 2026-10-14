@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultBatchedOvertimeMappingEngine(Kit.Flags.newRegistry())
        let item = Staffing.newBatchedOvertimeMapping("code-871", label: "label-54")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
