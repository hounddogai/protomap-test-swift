@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedCareGapBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedCareGapBundleStore = CareManagement.newMemoryBatchedCareGapBundleStore()
        let item = CareManagement.newBatchedCareGapBundle("code-473", name: "name-849")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
