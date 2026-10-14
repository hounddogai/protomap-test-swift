@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualDisclosurePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualDisclosurePolicyStore = Consent.newMemoryManualDisclosurePolicyStore()
        let item = Consent.newManualDisclosurePolicy("code-129", title: "title-739")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
