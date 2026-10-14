@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationScoreStore = Consent.newMemoryRevocationScoreStore()
        let item = Consent.newRevocationScore("code-345", label: "label-42")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
