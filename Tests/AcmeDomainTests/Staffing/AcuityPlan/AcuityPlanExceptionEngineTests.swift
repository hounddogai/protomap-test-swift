@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAcuityPlanExceptionEngine()
        let item = Staffing.newAcuityPlanException("code-126", name: "name-538")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
