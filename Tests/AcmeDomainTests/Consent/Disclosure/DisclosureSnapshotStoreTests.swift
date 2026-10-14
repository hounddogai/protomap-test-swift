@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureSnapshotStore = Consent.newMemoryDisclosureSnapshotStore()
        let item = Consent.newDisclosureSnapshot("code-940", title: "title-514")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
