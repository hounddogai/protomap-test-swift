@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardSnapshotStore = BedManagement.newMemoryBedBoardSnapshotStore()
        let item = BedManagement.newBedBoardSnapshot("code-590", name: "name-92")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
