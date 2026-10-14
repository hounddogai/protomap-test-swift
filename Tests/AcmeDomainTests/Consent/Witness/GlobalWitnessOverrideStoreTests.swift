@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalWitnessOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalWitnessOverrideStore = Consent.newMemoryGlobalWitnessOverrideStore()
        let item = Consent.newGlobalWitnessOverride("code-120", label: "label-457")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
