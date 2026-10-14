@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachSnapshotStore = CareManagement.newMemoryOutreachSnapshotStore()
        let item = CareManagement.newOutreachSnapshot("code-387", title: "title-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
