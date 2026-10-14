@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetDigestStore = ClinicalOps.newMemoryOrderSetDigestStore()
        let item = ClinicalOps.newOrderSetDigest("code-685", title: "title-455")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
