@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetProfileStore = ClinicalOps.newMemoryOrderSetProfileStore()
        let item = ClinicalOps.newOrderSetProfile("code-594", name: "name-151")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
