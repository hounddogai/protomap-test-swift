@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultGlobalAcuityPlanExceptionEngine()
        let item = Staffing.newGlobalAcuityPlanException("code-267", title: "title-829")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
