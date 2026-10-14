@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRegionalConsentFormTargetEngine(Kit.Flags.newRegistry())
        let item = Consent.newRegionalConsentFormTarget("code-886", title: "title-485")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
