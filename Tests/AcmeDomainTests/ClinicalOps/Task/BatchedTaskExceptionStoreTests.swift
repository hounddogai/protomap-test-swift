@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryBatchedTaskExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.BatchedTaskExceptionStore = ClinicalOps.newMemoryBatchedTaskExceptionStore()
        let item = ClinicalOps.newBatchedTaskException("code-814", label: "label-80")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
