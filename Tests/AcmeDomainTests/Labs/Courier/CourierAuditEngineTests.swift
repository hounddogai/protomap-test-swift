@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierAuditEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierAudit("code-948", title: "title-3")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
