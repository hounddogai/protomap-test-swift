@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryCredentialAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryCredentialAllocationStore = Staffing.newMemoryPrimaryCredentialAllocationStore()
        let item = Staffing.newPrimaryCredentialAllocation("code-324", title: "title-629")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
