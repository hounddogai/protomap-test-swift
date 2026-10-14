@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyEntryEngine()
        let item = Consent.newProxyEntry("code-154", label: "label-417")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
