@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessOverrideStore = Consent.newMemoryWitnessOverrideStore()
        let item = Consent.newWitnessOverride("code-134", title: "title-641")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
