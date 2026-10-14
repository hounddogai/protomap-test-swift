@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryIsolationScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryIsolationScheduleStore = BedManagement.newMemoryPrimaryIsolationScheduleStore()
        let item = BedManagement.newPrimaryIsolationSchedule("code-883", name: "name-770")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
