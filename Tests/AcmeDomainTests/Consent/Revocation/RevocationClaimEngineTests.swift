@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRevocationClaimEngine(Kit.Flags.newRegistry())
        let item = Consent.newRevocationClaim("code-404", title: "title-640")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
