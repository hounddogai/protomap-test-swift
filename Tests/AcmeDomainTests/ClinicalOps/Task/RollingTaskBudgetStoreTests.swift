@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingTaskBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingTaskBudgetStore = ClinicalOps.newMemoryRollingTaskBudgetStore()
        let item = ClinicalOps.newRollingTaskBudget("code-956", name: "name-650")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
