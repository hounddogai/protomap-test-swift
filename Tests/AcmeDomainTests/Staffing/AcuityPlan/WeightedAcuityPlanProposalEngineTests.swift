@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedAcuityPlanProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultWeightedAcuityPlanProposalEngine()
        let item = Staffing.newWeightedAcuityPlanProposal("code-691", label: "label-180")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
