@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledClosureRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledClosureRequestStore = Referrals.newMemoryScheduledClosureRequestStore()
        let item = Referrals.newScheduledClosureRequest("code-914", title: "title-762")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
