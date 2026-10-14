@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingCareProtocolTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultRollingCareProtocolTierEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newRollingCareProtocolTier("code-386", name: "name-212")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
