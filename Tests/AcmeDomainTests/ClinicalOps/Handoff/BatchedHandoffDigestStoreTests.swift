@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryBatchedHandoffDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.BatchedHandoffDigestStore = ClinicalOps.newMemoryBatchedHandoffDigestStore()
        let item = ClinicalOps.newBatchedHandoffDigest("code-299", title: "title-51")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
