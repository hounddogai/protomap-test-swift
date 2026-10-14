@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationPolicyStore = BedManagement.newMemoryIsolationPolicyStore()
        let item = BedManagement.newIsolationPolicy("code-208", label: "label-735")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
