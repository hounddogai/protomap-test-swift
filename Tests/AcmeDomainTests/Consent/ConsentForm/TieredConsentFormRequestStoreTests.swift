@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryTieredConsentFormRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.TieredConsentFormRequestStore = Consent.newMemoryTieredConsentFormRequestStore()
        let item = Consent.newTieredConsentFormRequest("code-9", label: "label-632")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
