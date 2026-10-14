@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingConsentFormWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingConsentFormWindowStore = Consent.newMemoryRollingConsentFormWindowStore()
        let item = Consent.newRollingConsentFormWindow("code-122", title: "title-208")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
