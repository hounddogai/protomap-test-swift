@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacySlotThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacySlotThresholdStore = Referrals.newMemoryLegacySlotThresholdStore()
        let item = Referrals.newLegacySlotThreshold("code-992", label: "label-903")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
