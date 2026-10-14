@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualClosureRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualClosureRollupStore = Referrals.newMemoryManualClosureRollupStore()
        let item = Referrals.newManualClosureRollup("code-955", title: "title-684")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
