@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetTargetStore = ClinicalOps.newMemoryOrderSetTargetStore()
        let item = ClinicalOps.newOrderSetTarget("code-330", name: "name-993")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
