@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredIsolationGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredIsolationGroupStore = BedManagement.newMemoryTieredIsolationGroupStore()
        let item = BedManagement.newTieredIsolationGroup("code-315", name: "name-804")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
