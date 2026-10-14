@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyFormularySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyFormularySnapshotStore = Pharmacy.newMemoryLegacyFormularySnapshotStore()
        let item = Pharmacy.newLegacyFormularySnapshot("code-207", title: "title-928")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
