@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedSpecimenTierEngine()
        let item = Labs.newCappedSpecimenTier("code-394", name: "name-744")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
