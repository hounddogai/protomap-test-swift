@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultDefaultSpecimenPolicyEngine(Kit.Flags.newRegistry())
        let item = Labs.newDefaultSpecimenPolicy("code-895", name: "name-164")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
