@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCappedRiskScoreClaimEngine()
        let item = CareManagement.newCappedRiskScoreClaim("code-153", title: "title-93")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
