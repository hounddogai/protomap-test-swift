@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationClaimStore = Consent.newMemoryRevocationClaimStore()
        let item = Consent.newRevocationClaim("code-404", title: "title-640")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
