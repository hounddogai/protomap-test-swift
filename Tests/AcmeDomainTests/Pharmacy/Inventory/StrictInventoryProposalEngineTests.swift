@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultStrictInventoryProposalEngine()
        let item = Pharmacy.newStrictInventoryProposal("code-180", label: "label-561")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
