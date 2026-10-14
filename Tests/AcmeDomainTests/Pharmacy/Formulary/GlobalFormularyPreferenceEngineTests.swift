@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalFormularyPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultGlobalFormularyPreferenceEngine()
        let item = Pharmacy.newGlobalFormularyPreference("code-383", label: "label-533")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
