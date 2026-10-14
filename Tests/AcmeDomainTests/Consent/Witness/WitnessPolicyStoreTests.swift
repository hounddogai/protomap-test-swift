@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessPolicyStore = Consent.newMemoryWitnessPolicyStore()
        let item = Consent.newWitnessPolicy("code-12", label: "label-56")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
