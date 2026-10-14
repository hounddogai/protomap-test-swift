@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxySnapshotStore = Consent.newMemoryProxySnapshotStore()
        let item = Consent.newProxySnapshot("code-556", name: "name-876")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
