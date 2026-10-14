@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingAccessionRecordEngine()
        let item = Labs.newRollingAccessionRecord("code-437", name: "name-406")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
