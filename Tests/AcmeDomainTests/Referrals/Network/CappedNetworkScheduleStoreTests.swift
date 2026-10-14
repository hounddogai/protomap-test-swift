@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedNetworkScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedNetworkScheduleStore = Referrals.newMemoryCappedNetworkScheduleStore()
        let item = Referrals.newCappedNetworkSchedule("code-2", label: "label-966")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
