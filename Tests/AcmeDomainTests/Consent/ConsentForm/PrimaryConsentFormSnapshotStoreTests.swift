@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryConsentFormSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryConsentFormSnapshotStore = Consent.newMemoryPrimaryConsentFormSnapshotStore()
        let item = Consent.newPrimaryConsentFormSnapshot("code-23", label: "label-487")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
