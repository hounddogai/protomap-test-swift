@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyPlanStore = Pharmacy.newMemoryFormularyPlanStore()
        let item = Pharmacy.newFormularyPlan("code-957", label: "label-406")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
