@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultShiftMetricEngine(Kit.Flags.newRegistry())
        let item = Staffing.newShiftMetric("code-613", label: "label-449")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
