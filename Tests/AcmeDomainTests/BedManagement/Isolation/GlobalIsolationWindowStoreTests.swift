@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryGlobalIsolationWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.GlobalIsolationWindowStore = BedManagement.newMemoryGlobalIsolationWindowStore()
        let item = BedManagement.newGlobalIsolationWindow("code-868", label: "label-458")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
