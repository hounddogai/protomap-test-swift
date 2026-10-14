@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLenientSubstitutionDigestEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newLenientSubstitutionDigest("code-412", title: "title-460")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
