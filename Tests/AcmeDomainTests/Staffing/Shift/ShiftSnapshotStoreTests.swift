@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftSnapshotStore = Staffing.newMemoryShiftSnapshotStore()
        let item = Staffing.newShiftSnapshot("code-68", name: "name-488")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
