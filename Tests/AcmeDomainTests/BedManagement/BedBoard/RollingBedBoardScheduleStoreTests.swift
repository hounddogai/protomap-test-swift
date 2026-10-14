@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRollingBedBoardScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RollingBedBoardScheduleStore = BedManagement.newMemoryRollingBedBoardScheduleStore()
        let item = BedManagement.newRollingBedBoardSchedule("code-41", label: "label-815")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
