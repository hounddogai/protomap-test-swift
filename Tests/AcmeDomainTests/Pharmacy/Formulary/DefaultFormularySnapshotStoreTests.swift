@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultFormularySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultFormularySnapshotStore = Pharmacy.newMemoryDefaultFormularySnapshotStore()
        let item = Pharmacy.newDefaultFormularySnapshot("code-611", name: "name-681")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
