@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalOutreachAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalOutreachAllocationStore = CareManagement.newMemoryGlobalOutreachAllocationStore()
        let item = CareManagement.newGlobalOutreachAllocation("code-308", label: "label-705")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
