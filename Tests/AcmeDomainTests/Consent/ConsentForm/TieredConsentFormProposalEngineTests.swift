@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultTieredConsentFormProposalEngine(Kit.Flags.newRegistry())
        let item = Consent.newTieredConsentFormProposal("code-149", label: "label-272")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
