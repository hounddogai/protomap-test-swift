@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardScheduleStore = BedManagement.newMemoryBedBoardScheduleStore()
        let item = BedManagement.newBedBoardSchedule("code-49", name: "name-589")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
