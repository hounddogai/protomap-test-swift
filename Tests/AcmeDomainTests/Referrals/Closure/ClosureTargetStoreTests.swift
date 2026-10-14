@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureTargetStore = Referrals.newMemoryClosureTargetStore()
        let item = Referrals.newClosureTarget("code-512", title: "title-597")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
