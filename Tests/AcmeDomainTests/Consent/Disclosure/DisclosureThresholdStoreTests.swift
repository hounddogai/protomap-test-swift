@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureThresholdStore = Consent.newMemoryDisclosureThresholdStore()
        let item = Consent.newDisclosureThreshold("code-917", name: "name-504")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
