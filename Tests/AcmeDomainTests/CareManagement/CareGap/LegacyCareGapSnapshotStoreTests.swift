@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyCareGapSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyCareGapSnapshotStore = CareManagement.newMemoryLegacyCareGapSnapshotStore()
        let item = CareManagement.newLegacyCareGapSnapshot("code-520", label: "label-791")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
