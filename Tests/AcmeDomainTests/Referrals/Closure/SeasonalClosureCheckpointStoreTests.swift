@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalClosureCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalClosureCheckpointStore = Referrals.newMemorySeasonalClosureCheckpointStore()
        let item = Referrals.newSeasonalClosureCheckpoint("code-834", title: "title-147")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
