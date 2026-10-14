@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultFallbackAssessmentManifestEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newFallbackAssessmentManifest("code-368", title: "title-496")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
