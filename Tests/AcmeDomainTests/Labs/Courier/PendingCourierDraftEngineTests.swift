@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingCourierDraftEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingCourierDraft("code-631", title: "title-365")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
