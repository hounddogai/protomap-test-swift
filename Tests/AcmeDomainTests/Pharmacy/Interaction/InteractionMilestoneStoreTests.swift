@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionMilestoneStore = Pharmacy.newMemoryInteractionMilestoneStore()
        let item = Pharmacy.newInteractionMilestone("code-742", name: "name-749")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
