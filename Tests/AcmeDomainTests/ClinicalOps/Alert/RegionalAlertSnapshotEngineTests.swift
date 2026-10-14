@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultRegionalAlertSnapshotEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newRegionalAlertSnapshot("code-285", label: "label-675")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
