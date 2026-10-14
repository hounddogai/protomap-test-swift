@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyAdjustmentStore = Pharmacy.newMemoryFormularyAdjustmentStore()
        let item = Pharmacy.newFormularyAdjustment("code-918", label: "label-591")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
