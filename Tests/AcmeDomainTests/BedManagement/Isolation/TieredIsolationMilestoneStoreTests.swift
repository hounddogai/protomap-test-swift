@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredIsolationMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredIsolationMilestoneStore = BedManagement.newMemoryTieredIsolationMilestoneStore()
        let item = BedManagement.newTieredIsolationMilestone("code-161", name: "name-875")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
