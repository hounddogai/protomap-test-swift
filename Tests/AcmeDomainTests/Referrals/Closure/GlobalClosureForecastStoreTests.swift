@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalClosureForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalClosureForecastStore = Referrals.newMemoryGlobalClosureForecastStore()
        let item = Referrals.newGlobalClosureForecast("code-350", title: "title-483")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
