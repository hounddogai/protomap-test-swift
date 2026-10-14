@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalSlotDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalSlotDigestStore = Referrals.newMemoryRegionalSlotDigestStore()
        let item = Referrals.newRegionalSlotDigest("code-306", label: "label-960")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
