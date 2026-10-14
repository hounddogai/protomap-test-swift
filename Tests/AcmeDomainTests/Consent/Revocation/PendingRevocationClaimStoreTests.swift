@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingRevocationClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingRevocationClaimStore = Consent.newMemoryPendingRevocationClaimStore()
        let item = Consent.newPendingRevocationClaim("code-470", title: "title-261")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
