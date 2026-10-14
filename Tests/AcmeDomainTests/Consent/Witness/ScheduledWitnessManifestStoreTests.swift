@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledWitnessManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledWitnessManifestStore = Consent.newMemoryScheduledWitnessManifestStore()
        let item = Consent.newScheduledWitnessManifest("code-991", name: "name-447")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
