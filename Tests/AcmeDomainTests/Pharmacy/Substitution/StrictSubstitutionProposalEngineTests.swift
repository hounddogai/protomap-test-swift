@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictSubstitutionProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultStrictSubstitutionProposalEngine()
        let item = Pharmacy.newStrictSubstitutionProposal("code-368", name: "name-711")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
