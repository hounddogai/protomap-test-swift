@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryCourierManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPrimaryCourierManifestEngine()
        let item = Labs.newPrimaryCourierManifest("code-512", title: "title-761")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
