@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDefaultBedBoardCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DefaultBedBoardCheckpointStore = BedManagement.newMemoryDefaultBedBoardCheckpointStore()
        let item = BedManagement.newDefaultBedBoardCheckpoint("code-415", name: "name-897")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
