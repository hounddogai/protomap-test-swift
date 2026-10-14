@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryAdaptiveConsentFormCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.AdaptiveConsentFormCheckpointStore = Consent.newMemoryAdaptiveConsentFormCheckpointStore()
        let item = Consent.newAdaptiveConsentFormCheckpoint("code-911", title: "title-408")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
