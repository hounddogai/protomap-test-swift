@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureDraftStore = Consent.newMemoryDisclosureDraftStore()
        let item = Consent.newDisclosureDraft("code-660", label: "label-389")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
