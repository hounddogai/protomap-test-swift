@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRegionalOutreachAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RegionalOutreachAllocationStore = CareManagement.newMemoryRegionalOutreachAllocationStore()
        let item = CareManagement.newRegionalOutreachAllocation("code-467", label: "label-461")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
