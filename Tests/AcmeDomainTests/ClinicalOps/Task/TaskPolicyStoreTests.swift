@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskPolicyStore = ClinicalOps.newMemoryTaskPolicyStore()
        let item = ClinicalOps.newTaskPolicy("code-690", title: "title-481")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
