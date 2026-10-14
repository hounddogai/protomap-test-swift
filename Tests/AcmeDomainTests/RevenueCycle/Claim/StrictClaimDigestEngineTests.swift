@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultStrictClaimDigestEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newStrictClaimDigest("code-630", name: "name-755")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
