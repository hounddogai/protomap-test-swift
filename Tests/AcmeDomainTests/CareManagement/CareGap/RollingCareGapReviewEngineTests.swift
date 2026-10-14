@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRollingCareGapReviewEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRollingCareGapReview("code-396", title: "title-516")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
