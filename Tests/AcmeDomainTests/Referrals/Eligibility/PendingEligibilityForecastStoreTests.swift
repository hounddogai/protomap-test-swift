@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingEligibilityForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingEligibilityForecastStore = Referrals.newMemoryPendingEligibilityForecastStore()
        let item = Referrals.newPendingEligibilityForecast("code-668", label: "label-894")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
