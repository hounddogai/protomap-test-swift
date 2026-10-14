@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPrimaryAccessionGroupEngine()
        let item = Labs.newPrimaryAccessionGroup("code-538", label: "label-433")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
