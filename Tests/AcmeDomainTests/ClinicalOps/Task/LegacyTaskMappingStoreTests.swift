@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyTaskMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyTaskMappingStore = ClinicalOps.newMemoryLegacyTaskMappingStore()
        let item = ClinicalOps.newLegacyTaskMapping("code-528", title: "title-607")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
