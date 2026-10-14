@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackDisclosureProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackDisclosureProfileStore = Consent.newMemoryFallbackDisclosureProfileStore()
        let item = Consent.newFallbackDisclosureProfile("code-699", title: "title-370")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
