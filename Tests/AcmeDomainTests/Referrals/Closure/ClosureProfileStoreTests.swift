@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureProfileStore = Referrals.newMemoryClosureProfileStore()
        let item = Referrals.newClosureProfile("code-567", title: "title-73")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
