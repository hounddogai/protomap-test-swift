@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureDigestStore = Consent.newMemoryDisclosureDigestStore()
        let item = Consent.newDisclosureDigest("code-402", label: "label-400")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
