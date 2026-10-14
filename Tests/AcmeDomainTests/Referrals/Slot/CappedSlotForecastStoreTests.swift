@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedSlotForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedSlotForecastStore = Referrals.newMemoryCappedSlotForecastStore()
        let item = Referrals.newCappedSlotForecast("code-875", name: "name-182")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
