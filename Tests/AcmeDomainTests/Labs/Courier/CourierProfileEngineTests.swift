@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierProfileEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierProfile("code-173", title: "title-62")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
