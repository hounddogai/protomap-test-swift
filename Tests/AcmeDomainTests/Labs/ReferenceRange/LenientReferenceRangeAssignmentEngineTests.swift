@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientReferenceRangeAssignmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newLenientReferenceRangeAssignment("code-341", label: "label-48")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
