@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingRevocationManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingRevocationManifestStore = Consent.newMemoryRollingRevocationManifestStore()
        let item = Consent.newRollingRevocationManifest("code-919", name: "name-342")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
