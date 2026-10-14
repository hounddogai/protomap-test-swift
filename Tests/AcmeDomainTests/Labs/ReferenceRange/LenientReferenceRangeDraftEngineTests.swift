@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientReferenceRangeDraftEngine(Kit.Flags.newRegistry())
        let item = Labs.newLenientReferenceRangeDraft("code-250", title: "title-55")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
