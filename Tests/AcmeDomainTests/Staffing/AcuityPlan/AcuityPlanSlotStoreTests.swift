@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanSlotStore = Staffing.newMemoryAcuityPlanSlotStore()
        let item = Staffing.newAcuityPlanSlot("code-58", label: "label-440")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
