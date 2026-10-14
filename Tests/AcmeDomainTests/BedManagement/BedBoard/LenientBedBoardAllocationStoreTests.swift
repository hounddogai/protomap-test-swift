@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientBedBoardAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientBedBoardAllocationStore = BedManagement.newMemoryLenientBedBoardAllocationStore()
        let item = BedManagement.newLenientBedBoardAllocation("code-47", label: "label-987")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
