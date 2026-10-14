@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationTierStore = Consent.newMemoryRevocationTierStore()
        let item = Consent.newRevocationTier("code-809", title: "title-52")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
