@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledLanguageCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledLanguageCycleStore = Consent.newMemoryScheduledLanguageCycleStore()
        let item = Consent.newScheduledLanguageCycle("code-604", title: "title-976")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
