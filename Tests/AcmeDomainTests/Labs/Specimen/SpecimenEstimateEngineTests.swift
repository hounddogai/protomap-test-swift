@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSpecimenEstimateEngine(Kit.Flags.newRegistry())
        let item = Labs.newSpecimenEstimate("code-983", name: "name-130")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
