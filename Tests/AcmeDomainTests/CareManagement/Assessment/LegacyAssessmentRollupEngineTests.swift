@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyAssessmentRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLegacyAssessmentRollupEngine()
        let item = CareManagement.newLegacyAssessmentRollup("code-130", label: "label-409")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
