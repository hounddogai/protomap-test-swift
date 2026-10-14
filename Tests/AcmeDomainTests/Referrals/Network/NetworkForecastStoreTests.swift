@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkForecastStore = Referrals.newMemoryNetworkForecastStore()
        let item = Referrals.newNetworkForecast("code-424", title: "title-185")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
