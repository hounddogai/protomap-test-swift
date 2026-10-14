@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralCheckpointStore = Referrals.newMemoryReferralCheckpointStore()
        let item = Referrals.newReferralCheckpoint("code-875", name: "name-147")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
