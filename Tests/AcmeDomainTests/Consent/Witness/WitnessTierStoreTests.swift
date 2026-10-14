@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessTierStore = Consent.newMemoryWitnessTierStore()
        let item = Consent.newWitnessTier("code-85", name: "name-885")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
