@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRegionalResultDigestEngine()
        let item = Labs.newRegionalResultDigest("code-406", label: "label-858")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
