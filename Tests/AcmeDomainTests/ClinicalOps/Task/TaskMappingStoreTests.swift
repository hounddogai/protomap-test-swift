@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskMappingStore = ClinicalOps.newMemoryTaskMappingStore()
        let item = ClinicalOps.newTaskMapping("code-692", title: "title-116")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
