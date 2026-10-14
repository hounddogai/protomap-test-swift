@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardMappingStore = BedManagement.newMemoryBedBoardMappingStore()
        let item = BedManagement.newBedBoardMapping("code-575", label: "label-935")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
