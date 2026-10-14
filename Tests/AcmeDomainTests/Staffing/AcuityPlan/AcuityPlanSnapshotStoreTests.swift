@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanSnapshotStore = Staffing.newMemoryAcuityPlanSnapshotStore()
        let item = Staffing.newAcuityPlanSnapshot("code-475", name: "name-346")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
