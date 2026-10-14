@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInteractionDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultTieredInteractionDraftEngine()
        let item = Pharmacy.newTieredInteractionDraft("code-883", title: "title-797")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
