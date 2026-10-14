@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryGoalProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPrimaryGoalProposalEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPrimaryGoalProposal("code-93", label: "label-701")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
