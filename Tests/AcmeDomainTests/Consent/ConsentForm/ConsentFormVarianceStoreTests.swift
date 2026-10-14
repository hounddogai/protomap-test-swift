@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormVarianceStore = Consent.newMemoryConsentFormVarianceStore()
        let item = Consent.newConsentFormVariance("code-851", label: "label-196")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
