@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualCareGapAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualCareGapAllocationStore = CareManagement.newMemoryManualCareGapAllocationStore()
        let item = CareManagement.newManualCareGapAllocation("code-931", title: "title-351")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
