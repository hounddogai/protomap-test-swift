@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCappedDischargePlanItemStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CappedDischargePlanItemStore = BedManagement.newMemoryCappedDischargePlanItemStore()
        let item = BedManagement.newCappedDischargePlanItem("code-89", name: "name-724")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
