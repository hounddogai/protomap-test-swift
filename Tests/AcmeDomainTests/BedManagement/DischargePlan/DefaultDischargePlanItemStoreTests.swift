@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDefaultDischargePlanItemStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DefaultDischargePlanItemStore = BedManagement.newMemoryDefaultDischargePlanItemStore()
        let item = BedManagement.newDefaultDischargePlanItem("code-123", name: "name-216")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
