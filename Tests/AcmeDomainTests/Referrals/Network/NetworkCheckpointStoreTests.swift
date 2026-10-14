@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkCheckpointStore = Referrals.newMemoryNetworkCheckpointStore()
        let item = Referrals.newNetworkCheckpoint("code-148", name: "name-777")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
