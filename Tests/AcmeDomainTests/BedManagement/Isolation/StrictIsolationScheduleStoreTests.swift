@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryStrictIsolationScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.StrictIsolationScheduleStore = BedManagement.newMemoryStrictIsolationScheduleStore()
        let item = BedManagement.newStrictIsolationSchedule("code-666", label: "label-17")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
