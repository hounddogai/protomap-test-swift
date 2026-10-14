@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryDischargePlanQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryDischargePlanQuotaStore = BedManagement.newMemoryPrimaryDischargePlanQuotaStore()
        let item = BedManagement.newPrimaryDischargePlanQuota("code-774", name: "name-507")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
