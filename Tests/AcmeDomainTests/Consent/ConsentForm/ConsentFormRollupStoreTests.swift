@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormRollupStore = Consent.newMemoryConsentFormRollupStore()
        let item = Consent.newConsentFormRollup("code-195", label: "label-694")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
