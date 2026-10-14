@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLanguageLedgerEngine(Kit.Flags.newRegistry())
        let item = Consent.newLanguageLedger("code-102", name: "name-834")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
