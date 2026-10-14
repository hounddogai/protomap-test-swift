@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAssessmentProposalEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newAssessmentProposal("code-683", title: "title-104")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
