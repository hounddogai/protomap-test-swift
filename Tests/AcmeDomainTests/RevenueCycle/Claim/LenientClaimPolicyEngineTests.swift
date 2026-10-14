@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultLenientClaimPolicyEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newLenientClaimPolicy("code-42", name: "name-282")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
