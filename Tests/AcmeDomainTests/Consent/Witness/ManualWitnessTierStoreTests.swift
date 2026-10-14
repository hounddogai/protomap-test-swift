@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualWitnessTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualWitnessTierStore = Consent.newMemoryManualWitnessTierStore()
        let item = Consent.newManualWitnessTier("code-668", title: "title-892")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
