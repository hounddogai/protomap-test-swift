@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalHandoffCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalHandoffCycleStore = ClinicalOps.newMemoryRegionalHandoffCycleStore()
        let item = ClinicalOps.newRegionalHandoffCycle("code-757", title: "title-498")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
