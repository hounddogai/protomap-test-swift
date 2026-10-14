@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledConsentFormDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledConsentFormDraftStore = Consent.newMemoryScheduledConsentFormDraftStore()
        let item = Consent.newScheduledConsentFormDraft("code-870", title: "title-793")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
