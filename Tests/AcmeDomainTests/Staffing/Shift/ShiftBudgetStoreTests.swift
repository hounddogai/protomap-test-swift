@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftBudgetStore = Staffing.newMemoryShiftBudgetStore()
        let item = Staffing.newShiftBudget("code-503", title: "title-676")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
