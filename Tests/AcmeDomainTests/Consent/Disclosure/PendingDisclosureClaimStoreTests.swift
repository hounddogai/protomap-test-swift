@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingDisclosureClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingDisclosureClaimStore = Consent.newMemoryPendingDisclosureClaimStore()
        let item = Consent.newPendingDisclosureClaim("code-915", name: "name-850")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
