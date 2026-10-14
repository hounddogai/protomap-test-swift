@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultWeightedOrderSetQuotaEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newWeightedOrderSetQuota("code-612", label: "label-346")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
