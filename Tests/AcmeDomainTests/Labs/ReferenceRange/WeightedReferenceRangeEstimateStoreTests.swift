@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedReferenceRangeEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedReferenceRangeEstimateStore = Labs.newMemoryWeightedReferenceRangeEstimateStore()
        let item = Labs.newWeightedReferenceRangeEstimate("code-845", name: "name-27")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
