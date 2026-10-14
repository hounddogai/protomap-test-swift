@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultScheduledDispenseAgreementEngine()
        let item = Pharmacy.newScheduledDispenseAgreement("code-290", title: "title-418")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
