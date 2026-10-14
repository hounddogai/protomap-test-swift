@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeBudgetStore = Staffing.newMemoryOvertimeBudgetStore()
        let item = Staffing.newOvertimeBudget("code-595", name: "name-692")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
