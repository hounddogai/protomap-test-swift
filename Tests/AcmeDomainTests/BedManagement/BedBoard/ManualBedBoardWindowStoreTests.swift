@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualBedBoardWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualBedBoardWindowStore = BedManagement.newMemoryManualBedBoardWindowStore()
        let item = BedManagement.newManualBedBoardWindow("code-349", label: "label-237")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
