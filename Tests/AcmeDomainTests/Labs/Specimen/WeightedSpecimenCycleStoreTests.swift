@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedSpecimenCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedSpecimenCycleStore = Labs.newMemoryWeightedSpecimenCycleStore()
        let item = Labs.newWeightedSpecimenCycle("code-298", name: "name-573")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
