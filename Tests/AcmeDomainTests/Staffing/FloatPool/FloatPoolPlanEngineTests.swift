@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFloatPoolPlanEngine()
        let item = Staffing.newFloatPoolPlan("code-888", title: "title-929")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
