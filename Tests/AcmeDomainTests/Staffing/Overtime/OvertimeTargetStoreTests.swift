@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeTargetStore = Staffing.newMemoryOvertimeTargetStore()
        let item = Staffing.newOvertimeTarget("code-545", label: "label-102")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
