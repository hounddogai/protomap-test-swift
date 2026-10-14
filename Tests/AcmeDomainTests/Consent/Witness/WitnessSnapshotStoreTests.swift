@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessSnapshotStore = Consent.newMemoryWitnessSnapshotStore()
        let item = Consent.newWitnessSnapshot("code-729", title: "title-825")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
