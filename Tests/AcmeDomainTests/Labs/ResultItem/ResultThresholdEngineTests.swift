@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultThresholdEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultThreshold("code-298", label: "label-969")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
