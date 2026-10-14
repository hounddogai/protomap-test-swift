@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedConsentFormNoticeEngine(Kit.Flags.newRegistry())
        let item = Consent.newCappedConsentFormNotice("code-154", title: "title-271")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
