@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertBudgetStore = ClinicalOps.newMemoryAlertBudgetStore()
        let item = ClinicalOps.newAlertBudget("code-526", title: "title-353")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
