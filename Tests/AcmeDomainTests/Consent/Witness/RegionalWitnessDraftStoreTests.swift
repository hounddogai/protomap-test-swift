@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalWitnessDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalWitnessDraftStore = Consent.newMemoryRegionalWitnessDraftStore()
        let item = Consent.newRegionalWitnessDraft("code-637", label: "label-171")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
