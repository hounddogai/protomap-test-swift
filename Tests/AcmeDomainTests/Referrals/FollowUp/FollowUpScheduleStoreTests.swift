@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpScheduleStore = Referrals.newMemoryFollowUpScheduleStore()
        let item = Referrals.newFollowUpSchedule("code-985", label: "label-862")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
