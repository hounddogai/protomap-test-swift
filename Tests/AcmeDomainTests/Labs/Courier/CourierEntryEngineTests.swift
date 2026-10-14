@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierEntryEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierEntry("code-371", title: "title-450")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
