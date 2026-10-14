@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultInteractionAgreementEngine()
        let item = Pharmacy.newInteractionAgreement("code-219", label: "label-498")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
