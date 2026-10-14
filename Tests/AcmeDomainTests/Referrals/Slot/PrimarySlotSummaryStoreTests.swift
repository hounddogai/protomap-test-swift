@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimarySlotSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimarySlotSummaryStore = Referrals.newMemoryPrimarySlotSummaryStore()
        let item = Referrals.newPrimarySlotSummary("code-409", title: "title-746")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
