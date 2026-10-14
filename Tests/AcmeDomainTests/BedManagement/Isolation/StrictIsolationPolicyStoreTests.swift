@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryStrictIsolationPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.StrictIsolationPolicyStore = BedManagement.newMemoryStrictIsolationPolicyStore()
        let item = BedManagement.newStrictIsolationPolicy("code-295", label: "label-7")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
