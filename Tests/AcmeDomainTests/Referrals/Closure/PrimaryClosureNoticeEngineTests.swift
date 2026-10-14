@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPrimaryClosureNoticeEngine(Kit.Flags.newRegistry())
        let item = Referrals.newPrimaryClosureNotice("code-627", title: "title-354")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
