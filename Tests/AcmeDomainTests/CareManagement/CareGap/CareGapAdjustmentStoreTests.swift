@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapAdjustmentStore = CareManagement.newMemoryCareGapAdjustmentStore()
        let item = CareManagement.newCareGapAdjustment("code-532", label: "label-948")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
