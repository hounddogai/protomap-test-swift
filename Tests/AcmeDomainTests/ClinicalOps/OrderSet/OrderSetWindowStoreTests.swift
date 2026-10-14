@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetWindowStore = ClinicalOps.newMemoryOrderSetWindowStore()
        let item = ClinicalOps.newOrderSetWindow("code-968", title: "title-471")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
