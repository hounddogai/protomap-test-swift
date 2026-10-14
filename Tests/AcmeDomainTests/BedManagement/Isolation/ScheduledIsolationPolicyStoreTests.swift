@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledIsolationPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledIsolationPolicyStore = BedManagement.newMemoryScheduledIsolationPolicyStore()
        let item = BedManagement.newScheduledIsolationPolicy("code-960", name: "name-433")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
