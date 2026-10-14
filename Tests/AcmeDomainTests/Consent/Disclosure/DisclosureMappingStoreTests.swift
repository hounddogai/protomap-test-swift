@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureMappingStore = Consent.newMemoryDisclosureMappingStore()
        let item = Consent.newDisclosureMapping("code-406", title: "title-881")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
