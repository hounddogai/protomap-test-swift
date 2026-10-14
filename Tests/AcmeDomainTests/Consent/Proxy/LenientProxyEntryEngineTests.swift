@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientProxyEntryEngine(Kit.Flags.newRegistry())
        let item = Consent.newLenientProxyEntry("code-938", label: "label-789")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
