@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryIsolationTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryIsolationTargetStore = BedManagement.newMemoryPrimaryIsolationTargetStore()
        let item = BedManagement.newPrimaryIsolationTarget("code-202", name: "name-332")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
