@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedOrderSetTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedOrderSetTemplateStore = ClinicalOps.newMemoryCappedOrderSetTemplateStore()
        let item = ClinicalOps.newCappedOrderSetTemplate("code-975", name: "name-742")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
