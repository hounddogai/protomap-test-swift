@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationAllocationStore = BedManagement.newMemoryIsolationAllocationStore()
        let item = BedManagement.newIsolationAllocation("code-1", title: "title-918")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
