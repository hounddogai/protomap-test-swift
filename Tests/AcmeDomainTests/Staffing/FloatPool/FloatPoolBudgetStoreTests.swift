@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolBudgetStore = Staffing.newMemoryFloatPoolBudgetStore()
        let item = Staffing.newFloatPoolBudget("code-537", label: "label-573")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
