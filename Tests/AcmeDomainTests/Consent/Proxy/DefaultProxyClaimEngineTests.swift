@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDefaultProxyClaimEngine()
        let item = Consent.newDefaultProxyClaim("code-398", name: "name-611")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
