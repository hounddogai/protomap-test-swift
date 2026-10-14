@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientRiskScorePreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLenientRiskScorePreferenceEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newLenientRiskScorePreference("code-880", title: "title-78")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
