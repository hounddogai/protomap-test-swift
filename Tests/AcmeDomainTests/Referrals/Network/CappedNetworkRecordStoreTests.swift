@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedNetworkRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedNetworkRecordStore = Referrals.newMemoryCappedNetworkRecordStore()
        let item = Referrals.newCappedNetworkRecord("code-286", name: "name-264")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
