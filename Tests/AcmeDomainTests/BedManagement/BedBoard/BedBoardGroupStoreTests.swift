@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardGroupStore = BedManagement.newMemoryBedBoardGroupStore()
        let item = BedManagement.newBedBoardGroup("code-12", name: "name-372")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
