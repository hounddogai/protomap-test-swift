@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLegacyDischargePlanAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LegacyDischargePlanAdjustmentStore = BedManagement.newMemoryLegacyDischargePlanAdjustmentStore()
        let item = BedManagement.newLegacyDischargePlanAdjustment("code-414", label: "label-787")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
