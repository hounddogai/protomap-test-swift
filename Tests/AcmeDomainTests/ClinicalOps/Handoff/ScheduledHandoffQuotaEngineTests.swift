@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultScheduledHandoffQuotaEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newScheduledHandoffQuota("code-512", name: "name-633")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
