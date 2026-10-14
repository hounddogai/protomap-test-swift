@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingCareGapAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingCareGapAdjustmentStore = CareManagement.newMemoryRollingCareGapAdjustmentStore()
        let item = CareManagement.newRollingCareGapAdjustment("code-194", label: "label-186")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
