@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultScheduledAccessionDigestEngine()
        let item = Labs.newScheduledAccessionDigest("code-773", name: "name-657")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
