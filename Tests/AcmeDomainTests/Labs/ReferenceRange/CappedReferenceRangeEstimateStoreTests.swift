@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedReferenceRangeEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedReferenceRangeEstimateStore = Labs.newMemoryCappedReferenceRangeEstimateStore()
        let item = Labs.newCappedReferenceRangeEstimate("code-303", name: "name-987")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
