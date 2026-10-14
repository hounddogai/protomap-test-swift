@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultSubstitutionEntryEngine()
        let item = Pharmacy.newSubstitutionEntry("code-576", label: "label-193")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
