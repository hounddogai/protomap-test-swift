@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormRequestStore = Consent.newMemoryConsentFormRequestStore()
        let item = Consent.newConsentFormRequest("code-570", label: "label-876")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
