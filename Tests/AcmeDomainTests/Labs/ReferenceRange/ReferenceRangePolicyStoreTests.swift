@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangePolicyStore = Labs.newMemoryReferenceRangePolicyStore()
        let item = Labs.newReferenceRangePolicy("code-660", label: "label-168")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
