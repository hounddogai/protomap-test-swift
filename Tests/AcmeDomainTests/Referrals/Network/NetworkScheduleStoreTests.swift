@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkScheduleStore = Referrals.newMemoryNetworkScheduleStore()
        let item = Referrals.newNetworkSchedule("code-350", title: "title-499")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
