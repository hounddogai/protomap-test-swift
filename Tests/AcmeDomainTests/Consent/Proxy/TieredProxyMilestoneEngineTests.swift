@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultTieredProxyMilestoneEngine(Kit.Flags.newRegistry())
        let item = Consent.newTieredProxyMilestone("code-4", name: "name-289")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
