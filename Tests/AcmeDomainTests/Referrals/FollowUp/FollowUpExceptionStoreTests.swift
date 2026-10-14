@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpExceptionStore = Referrals.newMemoryFollowUpExceptionStore()
        let item = Referrals.newFollowUpException("code-333", label: "label-681")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
