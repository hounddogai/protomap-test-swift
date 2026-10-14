@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedCareProtocolCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedCareProtocolCheckpointStore = ClinicalOps.newMemoryCappedCareProtocolCheckpointStore()
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("code-321", title: "title-468")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
