@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeGroupStore = Labs.newMemoryReferenceRangeGroupStore()
        let item = Labs.newReferenceRangeGroup("code-635", label: "label-236")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
