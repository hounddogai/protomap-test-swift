@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalCareGapAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalCareGapAllocationStore = CareManagement.newMemoryGlobalCareGapAllocationStore()
        let item = CareManagement.newGlobalCareGapAllocation("code-994", title: "title-271")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
