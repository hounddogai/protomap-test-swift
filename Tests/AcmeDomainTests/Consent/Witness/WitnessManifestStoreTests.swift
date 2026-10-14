@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessManifestStore = Consent.newMemoryWitnessManifestStore()
        let item = Consent.newWitnessManifest("code-102", title: "title-464")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
