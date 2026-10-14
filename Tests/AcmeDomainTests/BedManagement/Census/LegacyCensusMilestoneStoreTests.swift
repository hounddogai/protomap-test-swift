@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLegacyCensusMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LegacyCensusMilestoneStore = BedManagement.newMemoryLegacyCensusMilestoneStore()
        let item = BedManagement.newLegacyCensusMilestone("code-20", name: "name-874")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
