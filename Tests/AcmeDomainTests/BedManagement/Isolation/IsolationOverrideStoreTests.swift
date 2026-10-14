@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationOverrideStore = BedManagement.newMemoryIsolationOverrideStore()
        let item = BedManagement.newIsolationOverride("code-545", title: "title-209")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
