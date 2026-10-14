@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryProgramCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryProgramCheckpointStore = CareManagement.newMemoryPrimaryProgramCheckpointStore()
        let item = CareManagement.newPrimaryProgramCheckpoint("code-683", title: "title-882")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
