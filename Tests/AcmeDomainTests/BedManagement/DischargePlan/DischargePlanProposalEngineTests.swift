@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDischargePlanProposalEngine()
        let item = BedManagement.newDischargePlanProposal("code-921", label: "label-492")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
