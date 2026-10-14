@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeEstimateStore = Labs.newMemoryReferenceRangeEstimateStore()
        let item = Labs.newReferenceRangeEstimate("code-331", title: "title-540")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
