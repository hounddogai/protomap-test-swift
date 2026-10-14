@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetClaimStore = ClinicalOps.newMemoryOrderSetClaimStore()
        let item = ClinicalOps.newOrderSetClaim("code-688", name: "name-261")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
