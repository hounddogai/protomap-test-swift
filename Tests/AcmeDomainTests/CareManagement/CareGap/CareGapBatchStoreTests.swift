@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapBatchStore = CareManagement.newMemoryCareGapBatchStore()
        let item = CareManagement.newCareGapBatch("code-806", name: "name-917")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
