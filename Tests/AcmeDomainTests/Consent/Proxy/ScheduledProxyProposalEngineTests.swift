@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultScheduledProxyProposalEngine(Kit.Flags.newRegistry())
        let item = Consent.newScheduledProxyProposal("code-142", label: "label-114")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
