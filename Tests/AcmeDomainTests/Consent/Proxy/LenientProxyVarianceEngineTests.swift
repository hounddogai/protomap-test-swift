@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientProxyVarianceEngine(Kit.Flags.newRegistry())
        let item = Consent.newLenientProxyVariance("code-291", name: "name-748")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
