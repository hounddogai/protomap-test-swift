@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyMilestoneEngine()
        let item = Consent.newProxyMilestone("code-524", name: "name-395")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
