@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyCheckpointEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyCheckpoint("code-16", title: "title-215")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
