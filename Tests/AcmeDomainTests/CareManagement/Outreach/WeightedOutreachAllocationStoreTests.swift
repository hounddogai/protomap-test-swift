@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedOutreachAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedOutreachAllocationStore = CareManagement.newMemoryWeightedOutreachAllocationStore()
        let item = CareManagement.newWeightedOutreachAllocation("code-606", name: "name-808")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
