@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedResultRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedResultRequestStore = Labs.newMemoryWeightedResultRequestStore()
        let item = Labs.newWeightedResultRequest("code-480", label: "label-545")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
