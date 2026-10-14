@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingCareGapAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingCareGapAllocationStore = CareManagement.newMemoryPendingCareGapAllocationStore()
        let item = CareManagement.newPendingCareGapAllocation("code-160", title: "title-594")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
