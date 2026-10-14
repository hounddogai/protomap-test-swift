@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapBudgetStore = CareManagement.newMemoryCareGapBudgetStore()
        let item = CareManagement.newCareGapBudget("code-707", name: "name-632")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
