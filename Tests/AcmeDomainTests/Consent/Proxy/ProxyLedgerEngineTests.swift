@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyLedgerEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyLedger("code-237", label: "label-883")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
