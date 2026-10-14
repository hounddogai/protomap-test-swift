@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryCensusCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryCensusCheckpointStore = BedManagement.newMemoryPrimaryCensusCheckpointStore()
        let item = BedManagement.newPrimaryCensusCheckpoint("code-768", title: "title-539")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
