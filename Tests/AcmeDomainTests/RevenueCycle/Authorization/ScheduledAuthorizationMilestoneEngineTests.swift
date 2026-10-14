@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultScheduledAuthorizationMilestoneEngine()
        let item = RevenueCycle.newScheduledAuthorizationMilestone("code-755", name: "name-887")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
