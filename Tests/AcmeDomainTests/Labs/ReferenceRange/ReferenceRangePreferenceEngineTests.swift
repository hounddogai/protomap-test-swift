@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangePreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultReferenceRangePreferenceEngine(Kit.Flags.newRegistry())
        let item = Labs.newReferenceRangePreference("code-481", title: "title-919")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
