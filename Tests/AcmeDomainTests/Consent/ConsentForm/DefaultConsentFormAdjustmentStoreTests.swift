@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultConsentFormAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultConsentFormAdjustmentStore = Consent.newMemoryDefaultConsentFormAdjustmentStore()
        let item = Consent.newDefaultConsentFormAdjustment("code-736", title: "title-403")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
