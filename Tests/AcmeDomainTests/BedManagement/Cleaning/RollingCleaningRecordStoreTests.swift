@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRollingCleaningRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RollingCleaningRecordStore = BedManagement.newMemoryRollingCleaningRecordStore()
        let item = BedManagement.newRollingCleaningRecord("code-694", title: "title-430")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
