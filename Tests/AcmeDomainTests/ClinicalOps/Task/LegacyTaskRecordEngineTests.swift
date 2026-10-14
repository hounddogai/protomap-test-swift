@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultLegacyTaskRecordEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newLegacyTaskRecord("code-55", label: "label-566")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
