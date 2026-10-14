@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveShiftBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAdaptiveShiftBaselineEngine()
        let item = Staffing.newAdaptiveShiftBaseline("code-601", name: "name-641")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
