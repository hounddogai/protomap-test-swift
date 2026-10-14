@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedCareGapBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedCareGapBatchStore = CareManagement.newMemoryCappedCareGapBatchStore()
        let item = CareManagement.newCappedCareGapBatch("code-357", name: "name-786")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
