@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetOverrideStore = ClinicalOps.newMemoryOrderSetOverrideStore()
        let item = ClinicalOps.newOrderSetOverride("code-718", label: "label-953")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
