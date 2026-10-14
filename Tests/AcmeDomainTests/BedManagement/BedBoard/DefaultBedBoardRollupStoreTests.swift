@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDefaultBedBoardRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DefaultBedBoardRollupStore = BedManagement.newMemoryDefaultBedBoardRollupStore()
        let item = BedManagement.newDefaultBedBoardRollup("code-909", label: "label-811")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
