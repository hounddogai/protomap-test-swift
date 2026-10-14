@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureGroupStore = Referrals.newMemoryClosureGroupStore()
        let item = Referrals.newClosureGroup("code-441", title: "title-394")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
