@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingDispenseAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultRollingDispenseAgreementEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newRollingDispenseAgreement("code-876", title: "title-418")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
