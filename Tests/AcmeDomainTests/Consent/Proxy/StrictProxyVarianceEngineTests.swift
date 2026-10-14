@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultStrictProxyVarianceEngine(Kit.Flags.newRegistry())
        let item = Consent.newStrictProxyVariance("code-51", title: "title-297")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
