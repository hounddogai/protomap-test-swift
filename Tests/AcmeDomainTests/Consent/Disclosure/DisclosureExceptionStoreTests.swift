@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureExceptionStore = Consent.newMemoryDisclosureExceptionStore()
        let item = Consent.newDisclosureException("code-542", name: "name-246")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
