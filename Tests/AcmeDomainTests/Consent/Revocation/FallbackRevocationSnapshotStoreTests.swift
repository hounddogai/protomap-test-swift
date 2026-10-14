@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackRevocationSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackRevocationSnapshotStore = Consent.newMemoryFallbackRevocationSnapshotStore()
        let item = Consent.newFallbackRevocationSnapshot("code-174", title: "title-379")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
