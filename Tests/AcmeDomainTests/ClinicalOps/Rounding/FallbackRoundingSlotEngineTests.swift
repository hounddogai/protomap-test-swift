@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultFallbackRoundingSlotEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newFallbackRoundingSlot("code-335", name: "name-333")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
