@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetNoticeStore = ClinicalOps.newMemoryOrderSetNoticeStore()
        let item = ClinicalOps.newOrderSetNotice("code-976", name: "name-2")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
