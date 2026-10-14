@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanItemStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanItemStore = BedManagement.newMemoryDischargePlanItemStore()
        let item = BedManagement.newDischargePlanItem("code-863", label: "label-324")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
