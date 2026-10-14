@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLegacyDisclosureClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LegacyDisclosureClaimStore = Consent.newMemoryLegacyDisclosureClaimStore()
        let item = Consent.newLegacyDisclosureClaim("code-155", label: "label-565")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
