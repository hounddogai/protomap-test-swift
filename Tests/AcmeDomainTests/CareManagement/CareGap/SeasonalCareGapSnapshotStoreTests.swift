@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalCareGapSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalCareGapSnapshotStore = CareManagement.newMemorySeasonalCareGapSnapshotStore()
        let item = CareManagement.newSeasonalCareGapSnapshot("code-356", name: "name-780")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
