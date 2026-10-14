@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictOrderSetRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictOrderSetRollupStore = ClinicalOps.newMemoryStrictOrderSetRollupStore()
        let item = ClinicalOps.newStrictOrderSetRollup("code-374", label: "label-152")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
