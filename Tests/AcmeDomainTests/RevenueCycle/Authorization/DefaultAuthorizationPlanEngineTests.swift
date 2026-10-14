@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultAuthorizationPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultDefaultAuthorizationPlanEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newDefaultAuthorizationPlan("code-342", name: "name-905")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
