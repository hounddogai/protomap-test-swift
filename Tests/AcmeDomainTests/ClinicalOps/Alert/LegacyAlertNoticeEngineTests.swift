@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyAlertNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultLegacyAlertNoticeEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newLegacyAlertNotice("code-108", name: "name-702")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
