@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormNoticeStore = Consent.newMemoryConsentFormNoticeStore()
        let item = Consent.newConsentFormNotice("code-914", name: "name-749")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
