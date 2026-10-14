@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryFloatPoolBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryFloatPoolBudgetStore = Staffing.newMemoryPrimaryFloatPoolBudgetStore()
        let item = Staffing.newPrimaryFloatPoolBudget("code-218", name: "name-570")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
