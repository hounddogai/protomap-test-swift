@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualClosureScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualClosureScoreStore = Referrals.newMemoryManualClosureScoreStore()
        let item = Referrals.newManualClosureScore("code-161", label: "label-611")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
