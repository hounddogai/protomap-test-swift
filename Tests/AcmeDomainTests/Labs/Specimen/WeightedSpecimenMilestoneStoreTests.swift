@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedSpecimenMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedSpecimenMilestoneStore = Labs.newMemoryWeightedSpecimenMilestoneStore()
        let item = Labs.newWeightedSpecimenMilestone("code-7", name: "name-826")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
