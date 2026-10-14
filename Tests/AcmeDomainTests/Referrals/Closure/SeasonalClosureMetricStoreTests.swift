@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalClosureMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalClosureMetricStore = Referrals.newMemorySeasonalClosureMetricStore()
        let item = Referrals.newSeasonalClosureMetric("code-309", name: "name-802")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
