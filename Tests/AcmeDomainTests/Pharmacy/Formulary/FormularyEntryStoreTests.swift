@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyEntryStore = Pharmacy.newMemoryFormularyEntryStore()
        let item = Pharmacy.newFormularyEntry("code-791", label: "label-255")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
