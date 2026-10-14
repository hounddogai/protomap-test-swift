@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureClaimStore = Consent.newMemoryDisclosureClaimStore()
        let item = Consent.newDisclosureClaim("code-394", name: "name-446")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
