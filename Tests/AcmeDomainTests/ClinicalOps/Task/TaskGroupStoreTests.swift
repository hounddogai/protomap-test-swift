@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskGroupStore = ClinicalOps.newMemoryTaskGroupStore()
        let item = ClinicalOps.newTaskGroup("code-781", title: "title-37")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
