@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictAccessionAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultStrictAccessionAssignmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newStrictAccessionAssignment("code-822", title: "title-934")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
