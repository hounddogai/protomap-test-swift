@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultWeightedCareGapClaimEngine()
        let item = CareManagement.newWeightedCareGapClaim("code-499", label: "label-456")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
