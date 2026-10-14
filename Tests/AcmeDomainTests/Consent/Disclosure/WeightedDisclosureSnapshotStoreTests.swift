@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWeightedDisclosureSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WeightedDisclosureSnapshotStore = Consent.newMemoryWeightedDisclosureSnapshotStore()
        let item = Consent.newWeightedDisclosureSnapshot("code-834", label: "label-654")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
