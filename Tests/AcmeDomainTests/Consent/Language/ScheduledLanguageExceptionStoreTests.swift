@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledLanguageExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledLanguageExceptionStore = Consent.newMemoryScheduledLanguageExceptionStore()
        let item = Consent.newScheduledLanguageException("code-737", label: "label-117")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
