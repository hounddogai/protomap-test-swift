@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultAssessmentEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultDefaultAssessmentEstimateEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newDefaultAssessmentEstimate("code-795", title: "title-255")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
