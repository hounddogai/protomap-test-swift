@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedOrderSetPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultBatchedOrderSetPreferenceEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newBatchedOrderSetPreference("code-468", label: "label-878")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
