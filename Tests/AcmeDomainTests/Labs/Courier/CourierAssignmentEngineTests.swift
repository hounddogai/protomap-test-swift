@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierAssignmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierAssignment("code-773", name: "name-322")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
