@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormSegmentStore = Consent.newMemoryConsentFormSegmentStore()
        let item = Consent.newConsentFormSegment("code-992", label: "label-866")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
