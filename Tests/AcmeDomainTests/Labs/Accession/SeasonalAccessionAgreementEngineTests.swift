@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSeasonalAccessionAgreementEngine()
        let item = Labs.newSeasonalAccessionAgreement("code-457", title: "title-270")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
