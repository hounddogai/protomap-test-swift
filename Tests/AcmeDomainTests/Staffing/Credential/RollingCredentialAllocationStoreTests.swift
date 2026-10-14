@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRollingCredentialAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RollingCredentialAllocationStore = Staffing.newMemoryRollingCredentialAllocationStore()
        let item = Staffing.newRollingCredentialAllocation("code-748", title: "title-279")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
