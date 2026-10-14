@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalResultSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultGlobalResultSummaryEngine(Kit.Flags.newRegistry())
        let item = Labs.newGlobalResultSummary("code-368", label: "label-396")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
