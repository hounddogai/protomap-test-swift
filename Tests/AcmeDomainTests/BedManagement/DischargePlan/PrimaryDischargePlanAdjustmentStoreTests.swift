@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryDischargePlanAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryDischargePlanAdjustmentStore = BedManagement.newMemoryPrimaryDischargePlanAdjustmentStore()
        let item = BedManagement.newPrimaryDischargePlanAdjustment("code-205", title: "title-474")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
