@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalDisclosureSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalDisclosureSnapshotStore = Consent.newMemoryRegionalDisclosureSnapshotStore()
        let item = Consent.newRegionalDisclosureSnapshot("code-613", title: "title-429")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
