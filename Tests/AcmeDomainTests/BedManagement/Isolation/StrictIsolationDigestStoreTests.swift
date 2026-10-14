@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryStrictIsolationDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.StrictIsolationDigestStore = BedManagement.newMemoryStrictIsolationDigestStore()
        let item = BedManagement.newStrictIsolationDigest("code-570", title: "title-168")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
