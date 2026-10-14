@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedConsentFormNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedConsentFormNoticeStore = Consent.newMemoryCappedConsentFormNoticeStore()
        let item = Consent.newCappedConsentFormNotice("code-154", title: "title-271")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
