@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingRevocationScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingRevocationScoreStore = Consent.newMemoryPendingRevocationScoreStore()
        let item = Consent.newPendingRevocationScore("code-366", label: "label-151")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
