@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultRegionalCareProtocolQuotaEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newRegionalCareProtocolQuota("code-900", name: "name-909")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
