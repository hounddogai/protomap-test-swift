@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultCappedNetworkRecordEngine(Kit.Flags.newRegistry())
        let item = Referrals.newCappedNetworkRecord("code-286", name: "name-264")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
