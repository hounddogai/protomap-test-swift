@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormScoreStore = Consent.newMemoryConsentFormScoreStore()
        let item = Consent.newConsentFormScore("code-867", name: "name-734")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
