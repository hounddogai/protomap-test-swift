@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanSlotStore = BedManagement.newMemoryDischargePlanSlotStore()
        let item = BedManagement.newDischargePlanSlot("code-556", name: "name-679")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
