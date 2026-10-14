@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPendingShiftBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PendingShiftBudgetStore = Staffing.newMemoryPendingShiftBudgetStore()
        let item = Staffing.newPendingShiftBudget("code-297", title: "title-981")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
