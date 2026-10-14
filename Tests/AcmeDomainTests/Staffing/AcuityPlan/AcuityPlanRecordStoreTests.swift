@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanRecordStore = Staffing.newMemoryAcuityPlanRecordStore()
        let item = Staffing.newAcuityPlanRecord("code-145", label: "label-864")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
