@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierPreferenceEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierPreference("code-784", title: "title-352")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
