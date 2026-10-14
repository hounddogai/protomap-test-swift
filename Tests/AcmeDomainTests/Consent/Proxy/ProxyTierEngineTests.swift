@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyTierEngine()
        let item = Consent.newProxyTier("code-981", name: "name-262")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
