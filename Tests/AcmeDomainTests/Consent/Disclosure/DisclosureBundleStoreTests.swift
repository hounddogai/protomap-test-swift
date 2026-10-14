@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureBundleStore = Consent.newMemoryDisclosureBundleStore()
        let item = Consent.newDisclosureBundle("code-389", title: "title-634")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
