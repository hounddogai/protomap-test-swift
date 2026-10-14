@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedCareGapAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedCareGapAdjustmentStore = CareManagement.newMemoryWeightedCareGapAdjustmentStore()
        let item = CareManagement.newWeightedCareGapAdjustment("code-971", title: "title-801")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
