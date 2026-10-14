@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLegacyOvertimeSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LegacyOvertimeSnapshotStore = Staffing.newMemoryLegacyOvertimeSnapshotStore()
        let item = Staffing.newLegacyOvertimeSnapshot("code-462", title: "title-721")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
