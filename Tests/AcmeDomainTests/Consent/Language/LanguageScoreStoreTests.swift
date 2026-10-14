@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageScoreStore = Consent.newMemoryLanguageScoreStore()
        let item = Consent.newLanguageScore("code-601", name: "name-852")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
