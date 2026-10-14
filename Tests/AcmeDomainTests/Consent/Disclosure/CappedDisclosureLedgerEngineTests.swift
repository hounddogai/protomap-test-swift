@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedDisclosureLedgerEngine()
        let item = Consent.newCappedDisclosureLedger("code-765", name: "name-50")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
