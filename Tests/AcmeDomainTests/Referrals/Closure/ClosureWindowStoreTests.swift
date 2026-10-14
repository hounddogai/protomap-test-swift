@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureWindowStore = Referrals.newMemoryClosureWindowStore()
        let item = Referrals.newClosureWindow("code-899", label: "label-527")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
