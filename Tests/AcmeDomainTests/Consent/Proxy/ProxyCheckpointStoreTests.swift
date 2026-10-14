@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyCheckpointStore = Consent.newMemoryProxyCheckpointStore()
        let item = Consent.newProxyCheckpoint("code-16", title: "title-215")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
