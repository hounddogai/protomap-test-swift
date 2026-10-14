@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultClosureLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultDefaultClosureLedgerEngine()
        let item = Referrals.newDefaultClosureLedger("code-62", title: "title-615")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
