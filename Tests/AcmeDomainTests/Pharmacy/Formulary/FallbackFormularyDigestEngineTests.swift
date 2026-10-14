@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultFallbackFormularyDigestEngine()
        let item = Pharmacy.newFallbackFormularyDigest("code-147", name: "name-426")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
