@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictEligibilityEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictEligibilityEntryStore = Referrals.newMemoryStrictEligibilityEntryStore()
        let item = Referrals.newStrictEligibilityEntry("code-15", title: "title-359")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
