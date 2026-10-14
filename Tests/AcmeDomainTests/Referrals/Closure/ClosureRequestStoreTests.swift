@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureRequestStore = Referrals.newMemoryClosureRequestStore()
        let item = Referrals.newClosureRequest("code-745", name: "name-576")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
