@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskRequestStore = ClinicalOps.newMemoryTaskRequestStore()
        let item = ClinicalOps.newTaskRequest("code-460", name: "name-189")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
