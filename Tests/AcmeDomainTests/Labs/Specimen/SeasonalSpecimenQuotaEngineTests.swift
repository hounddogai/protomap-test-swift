@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSeasonalSpecimenQuotaEngine()
        let item = Labs.newSeasonalSpecimenQuota("code-980", label: "label-498")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
