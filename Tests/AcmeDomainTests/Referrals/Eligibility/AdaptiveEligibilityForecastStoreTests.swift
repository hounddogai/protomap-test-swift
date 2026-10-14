@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveEligibilityForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveEligibilityForecastStore = Referrals.newMemoryAdaptiveEligibilityForecastStore()
        let item = Referrals.newAdaptiveEligibilityForecast("code-925", name: "name-496")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
