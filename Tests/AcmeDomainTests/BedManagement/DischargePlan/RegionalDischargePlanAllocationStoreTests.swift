@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRegionalDischargePlanAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RegionalDischargePlanAllocationStore = BedManagement.newMemoryRegionalDischargePlanAllocationStore()
        let item = BedManagement.newRegionalDischargePlanAllocation("code-533", label: "label-79")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
