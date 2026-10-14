@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingConsentFormCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingConsentFormCheckpointStore = Consent.newMemoryPendingConsentFormCheckpointStore()
        let item = Consent.newPendingConsentFormCheckpoint("code-238", name: "name-711")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
