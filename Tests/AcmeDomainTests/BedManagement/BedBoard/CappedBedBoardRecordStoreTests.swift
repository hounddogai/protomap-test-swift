@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCappedBedBoardRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CappedBedBoardRecordStore = BedManagement.newMemoryCappedBedBoardRecordStore()
        let item = BedManagement.newCappedBedBoardRecord("code-980", title: "title-105")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
