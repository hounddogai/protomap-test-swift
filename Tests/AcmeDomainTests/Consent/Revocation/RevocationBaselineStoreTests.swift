@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationBaselineStore = Consent.newMemoryRevocationBaselineStore()
        let item = Consent.newRevocationBaseline("code-930", label: "label-158")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
