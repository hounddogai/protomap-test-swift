@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRegionalCareGapEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RegionalCareGapEstimateStore = CareManagement.newMemoryRegionalCareGapEstimateStore()
        let item = CareManagement.newRegionalCareGapEstimate("code-996", label: "label-752")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
