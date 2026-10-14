@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetQuotaStore = ClinicalOps.newMemoryOrderSetQuotaStore()
        let item = ClinicalOps.newOrderSetQuota("code-163", label: "label-418")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
