@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultScheduledSpecimenTierEngine()
        let item = Labs.newScheduledSpecimenTier("code-958", title: "title-534")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
