@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualNetworkScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualNetworkScheduleStore = Referrals.newMemoryManualNetworkScheduleStore()
        let item = Referrals.newManualNetworkSchedule("code-76", name: "name-995")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
