@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormSnapshotStore = Consent.newMemoryConsentFormSnapshotStore()
        let item = Consent.newConsentFormSnapshot("code-150", label: "label-455")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
