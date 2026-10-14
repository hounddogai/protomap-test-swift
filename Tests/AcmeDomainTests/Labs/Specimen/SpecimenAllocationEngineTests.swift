@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSpecimenAllocationEngine()
        let item = Labs.newSpecimenAllocation("code-9", title: "title-131")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
