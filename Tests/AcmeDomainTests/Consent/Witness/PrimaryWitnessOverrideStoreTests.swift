@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryWitnessOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryWitnessOverrideStore = Consent.newMemoryPrimaryWitnessOverrideStore()
        let item = Consent.newPrimaryWitnessOverride("code-577", title: "title-114")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
