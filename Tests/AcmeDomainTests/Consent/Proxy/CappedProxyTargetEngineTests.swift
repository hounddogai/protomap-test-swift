@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedProxyTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedProxyTargetEngine()
        let item = Consent.newCappedProxyTarget("code-142", name: "name-196")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
