@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedAccessionWindowEngine()
        let item = Labs.newCappedAccessionWindow("code-182", title: "title-127")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
