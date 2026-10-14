@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationSegmentStore = Consent.newMemoryRevocationSegmentStore()
        let item = Consent.newRevocationSegment("code-705", label: "label-587")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
