@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyRollupEngine()
        let item = Consent.newProxyRollup("code-552", name: "name-927")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
