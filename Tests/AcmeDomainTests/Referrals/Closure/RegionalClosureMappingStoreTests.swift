@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalClosureMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalClosureMappingStore = Referrals.newMemoryRegionalClosureMappingStore()
        let item = Referrals.newRegionalClosureMapping("code-378", title: "title-748")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
