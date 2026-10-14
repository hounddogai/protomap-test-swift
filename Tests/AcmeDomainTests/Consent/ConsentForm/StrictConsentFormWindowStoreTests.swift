@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryStrictConsentFormWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.StrictConsentFormWindowStore = Consent.newMemoryStrictConsentFormWindowStore()
        let item = Consent.newStrictConsentFormWindow("code-846", name: "name-583")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
