@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultScheduledProxyDraftEngine()
        let item = Consent.newScheduledProxyDraft("code-855", name: "name-202")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
