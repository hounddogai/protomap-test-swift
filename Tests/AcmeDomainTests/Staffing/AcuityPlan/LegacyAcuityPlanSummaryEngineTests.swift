@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLegacyAcuityPlanSummaryEngine()
        let item = Staffing.newLegacyAcuityPlanSummary("code-611", title: "title-302")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
