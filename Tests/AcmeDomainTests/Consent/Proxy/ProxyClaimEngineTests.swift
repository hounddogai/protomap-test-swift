@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyClaimEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyClaim("code-594", title: "title-282")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
