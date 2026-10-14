@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryStrictBedBoardCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.StrictBedBoardCycleStore = BedManagement.newMemoryStrictBedBoardCycleStore()
        let item = BedManagement.newStrictBedBoardCycle("code-68", name: "name-324")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
