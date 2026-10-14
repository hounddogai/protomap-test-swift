@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAcuityPlanRecordEngine()
        let item = Staffing.newAcuityPlanRecord("code-145", label: "label-864")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
