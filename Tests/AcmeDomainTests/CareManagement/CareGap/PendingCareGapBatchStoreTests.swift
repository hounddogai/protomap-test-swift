@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingCareGapBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingCareGapBatchStore = CareManagement.newMemoryPendingCareGapBatchStore()
        let item = CareManagement.newPendingCareGapBatch("code-442", label: "label-568")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
