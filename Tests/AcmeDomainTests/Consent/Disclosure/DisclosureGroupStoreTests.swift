@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureGroupStore = Consent.newMemoryDisclosureGroupStore()
        let item = Consent.newDisclosureGroup("code-933", label: "label-460")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
