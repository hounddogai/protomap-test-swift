@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryDefaultClosureEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.DefaultClosureEntryStore = Referrals.newMemoryDefaultClosureEntryStore()
        let item = Referrals.newDefaultClosureEntry("code-396", title: "title-453")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
