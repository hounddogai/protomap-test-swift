@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyRecordStore = Pharmacy.newMemoryFormularyRecordStore()
        let item = Pharmacy.newFormularyRecord("code-89", name: "name-579")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
