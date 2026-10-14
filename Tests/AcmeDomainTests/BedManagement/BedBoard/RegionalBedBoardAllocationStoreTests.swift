@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRegionalBedBoardAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RegionalBedBoardAllocationStore = BedManagement.newMemoryRegionalBedBoardAllocationStore()
        let item = BedManagement.newRegionalBedBoardAllocation("code-731", title: "title-508")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
