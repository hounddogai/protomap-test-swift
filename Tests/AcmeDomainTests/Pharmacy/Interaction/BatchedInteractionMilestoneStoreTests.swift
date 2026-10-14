@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedInteractionMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedInteractionMilestoneStore = Pharmacy.newMemoryBatchedInteractionMilestoneStore()
        let item = Pharmacy.newBatchedInteractionMilestone("code-965", name: "name-516")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
