@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyTargetEngine()
        let item = Consent.newProxyTarget("code-477", name: "name-474")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
