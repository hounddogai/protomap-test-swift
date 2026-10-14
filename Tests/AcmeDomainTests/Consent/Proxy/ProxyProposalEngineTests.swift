@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyProposalEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyProposal("code-336", name: "name-159")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
