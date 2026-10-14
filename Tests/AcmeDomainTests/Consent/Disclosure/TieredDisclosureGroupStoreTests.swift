@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryTieredDisclosureGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.TieredDisclosureGroupStore = Consent.newMemoryTieredDisclosureGroupStore()
        let item = Consent.newTieredDisclosureGroup("code-952", name: "name-625")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
