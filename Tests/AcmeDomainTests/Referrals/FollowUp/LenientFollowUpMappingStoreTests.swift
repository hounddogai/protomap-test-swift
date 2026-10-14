@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientFollowUpMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientFollowUpMappingStore = Referrals.newMemoryLenientFollowUpMappingStore()
        let item = Referrals.newLenientFollowUpMapping("code-300", label: "label-930")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
