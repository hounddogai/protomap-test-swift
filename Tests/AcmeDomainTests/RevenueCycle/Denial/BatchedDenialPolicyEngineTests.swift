@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultBatchedDenialPolicyEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newBatchedDenialPolicy("code-117", title: "title-693")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
