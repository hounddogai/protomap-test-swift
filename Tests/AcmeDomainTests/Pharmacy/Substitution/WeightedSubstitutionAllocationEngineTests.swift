@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultWeightedSubstitutionAllocationEngine()
        let item = Pharmacy.newWeightedSubstitutionAllocation("code-810", title: "title-169")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
