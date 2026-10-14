@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPendingWitnessWindowEngine()
        let item = Consent.newPendingWitnessWindow("code-516", label: "label-174")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
