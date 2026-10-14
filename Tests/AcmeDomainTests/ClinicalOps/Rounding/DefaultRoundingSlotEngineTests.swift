@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultDefaultRoundingSlotEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newDefaultRoundingSlot("code-417", title: "title-934")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
