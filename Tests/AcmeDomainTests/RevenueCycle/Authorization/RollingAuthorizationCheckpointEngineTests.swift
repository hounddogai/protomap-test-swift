@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingAuthorizationCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultRollingAuthorizationCheckpointEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newRollingAuthorizationCheckpoint("code-515", name: "name-873")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
