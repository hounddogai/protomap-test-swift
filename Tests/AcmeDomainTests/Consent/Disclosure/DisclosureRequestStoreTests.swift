@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureRequestStore = Consent.newMemoryDisclosureRequestStore()
        let item = Consent.newDisclosureRequest("code-870", label: "label-641")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
