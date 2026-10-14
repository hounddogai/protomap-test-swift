@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyBaselineEngine()
        let item = Consent.newProxyBaseline("code-493", name: "name-679")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
