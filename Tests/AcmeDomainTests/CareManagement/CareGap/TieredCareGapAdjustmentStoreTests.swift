@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredCareGapAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredCareGapAdjustmentStore = CareManagement.newMemoryTieredCareGapAdjustmentStore()
        let item = CareManagement.newTieredCareGapAdjustment("code-652", title: "title-863")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
