@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyBatchStore = Pharmacy.newMemoryFormularyBatchStore()
        let item = Pharmacy.newFormularyBatch("code-660", title: "title-999")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
