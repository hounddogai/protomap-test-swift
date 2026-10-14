@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureMetricStore = Referrals.newMemoryClosureMetricStore()
        let item = Referrals.newClosureMetric("code-285", title: "title-883")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
