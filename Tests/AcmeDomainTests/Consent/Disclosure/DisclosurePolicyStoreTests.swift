@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosurePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosurePolicyStore = Consent.newMemoryDisclosurePolicyStore()
        let item = Consent.newDisclosurePolicy("code-417", name: "name-496")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
