@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCareGapProposalEngine()
        let item = CareManagement.newCareGapProposal("code-812", label: "label-726")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
