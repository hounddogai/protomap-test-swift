@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAdaptiveAssessmentThresholdEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newAdaptiveAssessmentThreshold("code-985", title: "title-955")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
