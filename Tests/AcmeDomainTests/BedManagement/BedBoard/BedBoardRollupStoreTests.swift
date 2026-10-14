@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardRollupStore = BedManagement.newMemoryBedBoardRollupStore()
        let item = BedManagement.newBedBoardRollup("code-282", label: "label-223")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
