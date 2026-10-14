@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskSegmentStore = ClinicalOps.newMemoryTaskSegmentStore()
        let item = ClinicalOps.newTaskSegment("code-356", name: "name-432")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
