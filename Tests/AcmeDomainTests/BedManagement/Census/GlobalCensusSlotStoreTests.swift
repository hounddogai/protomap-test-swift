@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryGlobalCensusSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.GlobalCensusSlotStore = BedManagement.newMemoryGlobalCensusSlotStore()
        let item = BedManagement.newGlobalCensusSlot("code-767", title: "title-763")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
