@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackDisclosureSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackDisclosureSegmentStore = Consent.newMemoryFallbackDisclosureSegmentStore()
        let item = Consent.newFallbackDisclosureSegment("code-292", name: "name-978")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
