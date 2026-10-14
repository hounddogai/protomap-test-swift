@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityEntryStore = Referrals.newMemoryEligibilityEntryStore()
        let item = Referrals.newEligibilityEntry("code-542", name: "name-842")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
