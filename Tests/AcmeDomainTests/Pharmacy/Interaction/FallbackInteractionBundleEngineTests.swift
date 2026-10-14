@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInteractionBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultFallbackInteractionBundleEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newFallbackInteractionBundle("code-141", title: "title-536")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
