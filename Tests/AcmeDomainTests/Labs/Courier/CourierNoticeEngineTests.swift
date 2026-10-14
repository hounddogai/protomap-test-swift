@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierNoticeEngine()
        let item = Labs.newCourierNotice("code-522", name: "name-837")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
