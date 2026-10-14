@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalDisclosureBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalDisclosureBaselineStore = Consent.newMemoryGlobalDisclosureBaselineStore()
        let item = Consent.newGlobalDisclosureBaseline("code-615", name: "name-426")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
