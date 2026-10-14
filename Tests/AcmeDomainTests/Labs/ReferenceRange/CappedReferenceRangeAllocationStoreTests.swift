@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedReferenceRangeAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedReferenceRangeAllocationStore = Labs.newMemoryCappedReferenceRangeAllocationStore()
        let item = Labs.newCappedReferenceRangeAllocation("code-685", name: "name-519")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
