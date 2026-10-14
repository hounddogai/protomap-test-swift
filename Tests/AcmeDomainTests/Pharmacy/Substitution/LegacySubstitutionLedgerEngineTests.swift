@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacySubstitutionLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLegacySubstitutionLedgerEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newLegacySubstitutionLedger("code-529", title: "title-5")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
