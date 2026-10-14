@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientSpecimenPolicyEngine()
        let item = Labs.newLenientSpecimenPolicy("code-486", title: "title-474")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
