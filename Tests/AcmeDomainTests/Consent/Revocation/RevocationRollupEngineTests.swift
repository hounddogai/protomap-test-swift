@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRevocationRollupEngine(Kit.Flags.newRegistry())
        let item = Consent.newRevocationRollup("code-466", label: "label-491")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
