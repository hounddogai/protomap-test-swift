@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationProfileStore = BedManagement.newMemoryIsolationProfileStore()
        let item = BedManagement.newIsolationProfile("code-917", name: "name-73")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
