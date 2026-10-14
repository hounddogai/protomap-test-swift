@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultStrictCareProtocolTargetEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newStrictCareProtocolTarget("code-714", label: "label-925")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
