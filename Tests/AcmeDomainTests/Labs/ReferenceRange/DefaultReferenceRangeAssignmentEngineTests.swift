@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultDefaultReferenceRangeAssignmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newDefaultReferenceRangeAssignment("code-691", name: "name-83")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
