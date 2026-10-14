@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultWitnessPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultWitnessPreferenceStore = Consent.newMemoryDefaultWitnessPreferenceStore()
        let item = Consent.newDefaultWitnessPreference("code-912", name: "name-185")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
