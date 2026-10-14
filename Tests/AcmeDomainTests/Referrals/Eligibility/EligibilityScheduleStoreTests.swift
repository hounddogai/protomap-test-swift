@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityScheduleStore = Referrals.newMemoryEligibilityScheduleStore()
        let item = Referrals.newEligibilitySchedule("code-114", label: "label-974")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
