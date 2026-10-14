@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualDischargePlanItemStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualDischargePlanItemStore = BedManagement.newMemoryManualDischargePlanItemStore()
        let item = BedManagement.newManualDischargePlanItem("code-8", title: "title-391")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
