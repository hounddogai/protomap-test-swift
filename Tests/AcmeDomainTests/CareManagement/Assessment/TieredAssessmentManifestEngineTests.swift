@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultTieredAssessmentManifestEngine()
        let item = CareManagement.newTieredAssessmentManifest("code-272", title: "title-96")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
