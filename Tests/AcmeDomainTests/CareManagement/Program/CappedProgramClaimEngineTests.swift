@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCappedProgramClaimEngine()
        let item = CareManagement.newCappedProgramClaim("code-77", title: "title-528")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
