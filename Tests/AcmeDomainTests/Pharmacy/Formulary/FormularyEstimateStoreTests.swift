@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyEstimateStore = Pharmacy.newMemoryFormularyEstimateStore()
        let item = Pharmacy.newFormularyEstimate("code-376", title: "title-731")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
