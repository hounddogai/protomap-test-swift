@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingOutreachCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingOutreachCheckpointStore = CareManagement.newMemoryPendingOutreachCheckpointStore()
        let item = CareManagement.newPendingOutreachCheckpoint("code-549", label: "label-460")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
