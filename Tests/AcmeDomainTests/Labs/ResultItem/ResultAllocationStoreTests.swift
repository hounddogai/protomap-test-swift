@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultAllocationStore = Labs.newMemoryResultAllocationStore()
        let item = Labs.newResultAllocation("code-587", title: "title-434")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
