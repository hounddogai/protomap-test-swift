@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackRevocationPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackRevocationPreferenceStore = Consent.newMemoryFallbackRevocationPreferenceStore()
        let item = Consent.newFallbackRevocationPreference("code-379", name: "name-235")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
