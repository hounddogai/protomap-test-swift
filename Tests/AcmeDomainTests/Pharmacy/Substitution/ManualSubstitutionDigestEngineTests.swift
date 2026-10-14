@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualSubstitutionDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultManualSubstitutionDigestEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newManualSubstitutionDigest("code-835", name: "name-699")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
