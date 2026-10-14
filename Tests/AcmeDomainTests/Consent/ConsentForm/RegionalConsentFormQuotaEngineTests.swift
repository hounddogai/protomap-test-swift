@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRegionalConsentFormQuotaEngine(Kit.Flags.newRegistry())
        let item = Consent.newRegionalConsentFormQuota("code-768", title: "title-444")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
