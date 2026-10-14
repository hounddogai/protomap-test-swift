@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanMappingStore = BedManagement.newMemoryDischargePlanMappingStore()
        let item = BedManagement.newDischargePlanMapping("code-512", label: "label-43")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
