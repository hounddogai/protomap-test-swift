@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryGlobalCensusCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.GlobalCensusCheckpointStore = BedManagement.newMemoryGlobalCensusCheckpointStore()
        let item = BedManagement.newGlobalCensusCheckpoint("code-794", title: "title-550")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
