@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryStrictDisclosureSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.StrictDisclosureSegmentStore = Consent.newMemoryStrictDisclosureSegmentStore()
        let item = Consent.newStrictDisclosureSegment("code-291", name: "name-602")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
