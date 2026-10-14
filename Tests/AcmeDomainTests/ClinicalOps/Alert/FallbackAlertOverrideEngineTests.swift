@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackAlertOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultFallbackAlertOverrideEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newFallbackAlertOverride("code-929", title: "title-599")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
