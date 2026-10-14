@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLenientClosureNoticeEngine(Kit.Flags.newRegistry())
        let item = Referrals.newLenientClosureNotice("code-410", title: "title-788")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
