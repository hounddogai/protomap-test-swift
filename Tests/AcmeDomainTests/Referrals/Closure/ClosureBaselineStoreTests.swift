@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureBaselineStore = Referrals.newMemoryClosureBaselineStore()
        let item = Referrals.newClosureBaseline("code-303", label: "label-518")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
