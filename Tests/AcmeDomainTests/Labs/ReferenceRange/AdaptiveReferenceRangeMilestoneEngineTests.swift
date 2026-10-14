@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveReferenceRangeMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAdaptiveReferenceRangeMilestoneEngine(Kit.Flags.newRegistry())
        let item = Labs.newAdaptiveReferenceRangeMilestone("code-507", title: "title-932")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
