@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierDigestEngine()
        let item = Labs.newCourierDigest("code-686", label: "label-238")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
