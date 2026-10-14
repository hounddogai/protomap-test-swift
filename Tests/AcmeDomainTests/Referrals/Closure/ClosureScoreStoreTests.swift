@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureScoreStore = Referrals.newMemoryClosureScoreStore()
        let item = Referrals.newClosureScore("code-960", title: "title-968")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
