@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultFormularyRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultFormularyRecordStore = Pharmacy.newMemoryDefaultFormularyRecordStore()
        let item = Pharmacy.newDefaultFormularyRecord("code-607", name: "name-826")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
