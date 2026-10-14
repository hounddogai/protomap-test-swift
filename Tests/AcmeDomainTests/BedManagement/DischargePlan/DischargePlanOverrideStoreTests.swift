@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanOverrideStore = BedManagement.newMemoryDischargePlanOverrideStore()
        let item = BedManagement.newDischargePlanOverride("code-728", name: "name-540")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
