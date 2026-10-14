@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularySnapshotStore = Pharmacy.newMemoryFormularySnapshotStore()
        let item = Pharmacy.newFormularySnapshot("code-317", title: "title-528")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
