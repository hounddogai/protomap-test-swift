@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedFormularySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedFormularySnapshotStore = Pharmacy.newMemoryCappedFormularySnapshotStore()
        let item = Pharmacy.newCappedFormularySnapshot("code-799", name: "name-316")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
