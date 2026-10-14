@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictReferenceRangeRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultStrictReferenceRangeRuleEngine(Kit.Flags.newRegistry())
        let item = Labs.newStrictReferenceRangeRule("code-413", name: "name-446")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
