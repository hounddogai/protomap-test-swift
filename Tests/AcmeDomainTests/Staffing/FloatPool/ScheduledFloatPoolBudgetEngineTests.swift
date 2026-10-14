@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultScheduledFloatPoolBudgetEngine()
        let item = Staffing.newScheduledFloatPoolBudget("code-958", title: "title-223")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
