@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftAdjustmentStore = Staffing.newMemoryShiftAdjustmentStore()
        let item = Staffing.newShiftAdjustment("code-40", label: "label-919")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
