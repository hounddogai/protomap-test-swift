@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyPreferenceEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyPreference("code-336", title: "title-324")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
