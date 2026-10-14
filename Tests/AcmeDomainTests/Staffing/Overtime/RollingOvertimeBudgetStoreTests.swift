@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRollingOvertimeBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RollingOvertimeBudgetStore = Staffing.newMemoryRollingOvertimeBudgetStore()
        let item = Staffing.newRollingOvertimeBudget("code-87", title: "title-275")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
