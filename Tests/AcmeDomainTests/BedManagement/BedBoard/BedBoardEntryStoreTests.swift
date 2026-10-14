@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardEntryStore = BedManagement.newMemoryBedBoardEntryStore()
        let item = BedManagement.newBedBoardEntry("code-232", title: "title-615")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
