@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredDischargePlanRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredDischargePlanRecordStore = BedManagement.newMemoryTieredDischargePlanRecordStore()
        let item = BedManagement.newTieredDischargePlanRecord("code-466", label: "label-340")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
