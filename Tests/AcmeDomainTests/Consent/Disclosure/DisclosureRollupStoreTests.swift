@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureRollupStore = Consent.newMemoryDisclosureRollupStore()
        let item = Consent.newDisclosureRollup("code-263", name: "name-268")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
