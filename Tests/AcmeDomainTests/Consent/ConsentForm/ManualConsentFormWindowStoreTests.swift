@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualConsentFormWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualConsentFormWindowStore = Consent.newMemoryManualConsentFormWindowStore()
        let item = Consent.newManualConsentFormWindow("code-979", title: "title-603")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
