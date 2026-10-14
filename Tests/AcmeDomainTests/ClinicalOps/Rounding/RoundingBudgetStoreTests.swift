@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingBudgetStore = ClinicalOps.newMemoryRoundingBudgetStore()
        let item = ClinicalOps.newRoundingBudget("code-227", title: "title-346")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
