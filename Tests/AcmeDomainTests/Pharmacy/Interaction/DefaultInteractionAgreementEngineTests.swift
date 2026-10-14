@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultDefaultInteractionAgreementEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newDefaultInteractionAgreement("code-808", title: "title-359")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
