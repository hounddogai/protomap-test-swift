@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardProfileStore = BedManagement.newMemoryBedBoardProfileStore()
        let item = BedManagement.newBedBoardProfile("code-177", name: "name-267")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
