@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftPolicyStore = Staffing.newMemoryShiftPolicyStore()
        let item = Staffing.newShiftPolicy("code-615", label: "label-680")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
