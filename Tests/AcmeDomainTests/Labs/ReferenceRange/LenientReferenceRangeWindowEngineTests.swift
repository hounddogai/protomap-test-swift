@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientReferenceRangeWindowEngine(Kit.Flags.newRegistry())
        let item = Labs.newLenientReferenceRangeWindow("code-174", name: "name-629")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
