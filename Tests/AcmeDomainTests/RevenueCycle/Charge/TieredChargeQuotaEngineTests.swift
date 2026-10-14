@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultTieredChargeQuotaEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newTieredChargeQuota("code-407", label: "label-415")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
