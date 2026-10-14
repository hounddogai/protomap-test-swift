@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationDigestStore = BedManagement.newMemoryIsolationDigestStore()
        let item = BedManagement.newIsolationDigest("code-495", title: "title-515")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
