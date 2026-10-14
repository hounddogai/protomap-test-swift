@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapSnapshotStore = CareManagement.newMemoryCareGapSnapshotStore()
        let item = CareManagement.newCareGapSnapshot("code-369", name: "name-804")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
