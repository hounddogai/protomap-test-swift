@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPrimaryAccessionClaimEngine()
        let item = Labs.newPrimaryAccessionClaim("code-884", name: "name-50")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
