@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackDischargePlanAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackDischargePlanAllocationStore = BedManagement.newMemoryFallbackDischargePlanAllocationStore()
        let item = BedManagement.newFallbackDischargePlanAllocation("code-17", label: "label-258")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
