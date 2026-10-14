@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalSlotOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalSlotOverrideStore = Referrals.newMemoryRegionalSlotOverrideStore()
        let item = Referrals.newRegionalSlotOverride("code-748", name: "name-841")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
