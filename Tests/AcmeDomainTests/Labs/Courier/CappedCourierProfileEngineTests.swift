@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedCourierProfileEngine()
        let item = Labs.newCappedCourierProfile("code-445", label: "label-662")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
