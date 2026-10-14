@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFallbackShiftBaselineEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFallbackShiftBaseline("code-671", name: "name-271")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
