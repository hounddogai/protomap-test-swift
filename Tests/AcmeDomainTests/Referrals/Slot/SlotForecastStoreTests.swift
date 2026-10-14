@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotForecastStore = Referrals.newMemorySlotForecastStore()
        let item = Referrals.newSlotForecast("code-920", name: "name-661")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
