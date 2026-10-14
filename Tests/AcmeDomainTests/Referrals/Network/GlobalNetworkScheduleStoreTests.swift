@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalNetworkScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalNetworkScheduleStore = Referrals.newMemoryGlobalNetworkScheduleStore()
        let item = Referrals.newGlobalNetworkSchedule("code-787", name: "name-817")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
