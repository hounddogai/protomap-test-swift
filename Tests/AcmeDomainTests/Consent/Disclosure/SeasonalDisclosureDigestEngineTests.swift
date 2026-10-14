@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultSeasonalDisclosureDigestEngine(Kit.Flags.newRegistry())
        let item = Consent.newSeasonalDisclosureDigest("code-874", title: "title-654")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
