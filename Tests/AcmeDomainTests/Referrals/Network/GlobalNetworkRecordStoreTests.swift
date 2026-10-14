@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalNetworkRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalNetworkRecordStore = Referrals.newMemoryGlobalNetworkRecordStore()
        let item = Referrals.newGlobalNetworkRecord("code-929", label: "label-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
