@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryTieredRevocationBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.TieredRevocationBaselineStore = Consent.newMemoryTieredRevocationBaselineStore()
        let item = Consent.newTieredRevocationBaseline("code-972", name: "name-87")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
