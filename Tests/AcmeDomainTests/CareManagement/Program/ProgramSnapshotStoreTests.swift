@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramSnapshotStore = CareManagement.newMemoryProgramSnapshotStore()
        let item = CareManagement.newProgramSnapshot("code-229", label: "label-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
