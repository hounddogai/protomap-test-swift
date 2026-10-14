@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedConsentFormRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWeightedConsentFormRollupEngine(Kit.Flags.newRegistry())
        let item = Consent.newWeightedConsentFormRollup("code-405", title: "title-728")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
