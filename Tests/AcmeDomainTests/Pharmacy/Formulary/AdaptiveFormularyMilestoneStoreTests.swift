@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveFormularyMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveFormularyMilestoneStore = Pharmacy.newMemoryAdaptiveFormularyMilestoneStore()
        let item = Pharmacy.newAdaptiveFormularyMilestone("code-138", title: "title-177")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
