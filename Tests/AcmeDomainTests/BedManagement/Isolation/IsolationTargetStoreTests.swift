@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationTargetStore = BedManagement.newMemoryIsolationTargetStore()
        let item = BedManagement.newIsolationTarget("code-882", label: "label-711")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
