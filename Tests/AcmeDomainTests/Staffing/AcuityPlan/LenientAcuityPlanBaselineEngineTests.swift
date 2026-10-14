@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLenientAcuityPlanBaselineEngine(Kit.Flags.newRegistry())
        let item = Staffing.newLenientAcuityPlanBaseline("code-328", label: "label-212")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
