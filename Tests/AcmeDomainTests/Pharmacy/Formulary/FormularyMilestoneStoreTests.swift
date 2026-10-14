@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyMilestoneStore = Pharmacy.newMemoryFormularyMilestoneStore()
        let item = Pharmacy.newFormularyMilestone("code-411", label: "label-662")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
