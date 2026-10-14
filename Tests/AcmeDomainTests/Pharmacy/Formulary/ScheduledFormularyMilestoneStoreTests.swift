@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryScheduledFormularyMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ScheduledFormularyMilestoneStore = Pharmacy.newMemoryScheduledFormularyMilestoneStore()
        let item = Pharmacy.newScheduledFormularyMilestone("code-529", title: "title-754")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
