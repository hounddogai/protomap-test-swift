@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapEstimateStore = CareManagement.newMemoryCareGapEstimateStore()
        let item = CareManagement.newCareGapEstimate("code-638", label: "label-464")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
