@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedHandoffMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedHandoffMappingStore = ClinicalOps.newMemoryCappedHandoffMappingStore()
        let item = ClinicalOps.newCappedHandoffMapping("code-612", name: "name-518")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
