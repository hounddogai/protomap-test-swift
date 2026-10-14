@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessBundleStore = Consent.newMemoryWitnessBundleStore()
        let item = Consent.newWitnessBundle("code-40", label: "label-28")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
