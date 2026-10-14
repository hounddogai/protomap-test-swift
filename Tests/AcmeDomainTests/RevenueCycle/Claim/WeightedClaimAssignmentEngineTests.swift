@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultWeightedClaimAssignmentEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newWeightedClaimAssignment("code-152", title: "title-119")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
