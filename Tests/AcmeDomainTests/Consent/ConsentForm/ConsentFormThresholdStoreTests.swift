@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormThresholdStore = Consent.newMemoryConsentFormThresholdStore()
        let item = Consent.newConsentFormThreshold("code-238", title: "title-588")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
