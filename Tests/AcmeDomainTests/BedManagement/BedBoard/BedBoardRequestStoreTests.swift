@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardRequestStore = BedManagement.newMemoryBedBoardRequestStore()
        let item = BedManagement.newBedBoardRequest("code-29", name: "name-113")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
