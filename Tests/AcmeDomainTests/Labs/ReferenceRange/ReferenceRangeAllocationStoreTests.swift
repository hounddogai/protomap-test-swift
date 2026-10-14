@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeAllocationStore = Labs.newMemoryReferenceRangeAllocationStore()
        let item = Labs.newReferenceRangeAllocation("code-299", label: "label-737")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
