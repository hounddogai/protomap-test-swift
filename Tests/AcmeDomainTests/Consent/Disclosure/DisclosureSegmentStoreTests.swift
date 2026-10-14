@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureSegmentStore = Consent.newMemoryDisclosureSegmentStore()
        let item = Consent.newDisclosureSegment("code-158", title: "title-913")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
