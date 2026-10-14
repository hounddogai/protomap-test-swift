@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingClosureProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingClosureProfileStore = Referrals.newMemoryRollingClosureProfileStore()
        let item = Referrals.newRollingClosureProfile("code-504", title: "title-949")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
