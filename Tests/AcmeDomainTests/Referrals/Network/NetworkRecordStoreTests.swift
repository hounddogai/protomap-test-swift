@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkRecordStore = Referrals.newMemoryNetworkRecordStore()
        let item = Referrals.newNetworkRecord("code-551", name: "name-270")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
