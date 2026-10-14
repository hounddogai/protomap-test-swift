@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormMappingStore = Consent.newMemoryConsentFormMappingStore()
        let item = Consent.newConsentFormMapping("code-972", label: "label-60")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
