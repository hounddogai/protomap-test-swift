@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackNetworkScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackNetworkScheduleStore = Referrals.newMemoryFallbackNetworkScheduleStore()
        let item = Referrals.newFallbackNetworkSchedule("code-824", name: "name-436")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
