@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultStrictShiftThresholdEngine()
        let item = Staffing.newStrictShiftThreshold("code-504", label: "label-534")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
