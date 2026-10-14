@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyExceptionEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyException("code-305", label: "label-368")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
