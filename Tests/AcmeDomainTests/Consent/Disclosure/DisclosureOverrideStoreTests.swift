@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureOverrideStore = Consent.newMemoryDisclosureOverrideStore()
        let item = Consent.newDisclosureOverride("code-660", label: "label-345")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
