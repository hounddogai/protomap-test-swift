@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftCheckpointStore = Staffing.newMemoryShiftCheckpointStore()
        let item = Staffing.newShiftCheckpoint("code-16", label: "label-523")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
