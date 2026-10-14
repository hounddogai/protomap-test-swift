@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularySlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultFormularySlotEngine()
        let item = Pharmacy.newFormularySlot("code-816", title: "title-381")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
