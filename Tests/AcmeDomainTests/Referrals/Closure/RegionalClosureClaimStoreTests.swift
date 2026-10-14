@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalClosureClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalClosureClaimStore = Referrals.newMemoryRegionalClosureClaimStore()
        let item = Referrals.newRegionalClosureClaim("code-110", title: "title-202")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
