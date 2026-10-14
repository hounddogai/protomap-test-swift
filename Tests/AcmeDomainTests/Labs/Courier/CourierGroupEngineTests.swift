@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierGroupEngine()
        let item = Labs.newCourierGroup("code-172", title: "title-214")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
