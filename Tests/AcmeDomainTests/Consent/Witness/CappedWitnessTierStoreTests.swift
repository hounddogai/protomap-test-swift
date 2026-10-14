@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedWitnessTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedWitnessTierStore = Consent.newMemoryCappedWitnessTierStore()
        let item = Consent.newCappedWitnessTier("code-874", name: "name-184")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
