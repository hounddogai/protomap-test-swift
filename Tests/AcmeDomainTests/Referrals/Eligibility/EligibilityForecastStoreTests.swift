@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityForecastStore = Referrals.newMemoryEligibilityForecastStore()
        let item = Referrals.newEligibilityForecast("code-703", label: "label-903")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
