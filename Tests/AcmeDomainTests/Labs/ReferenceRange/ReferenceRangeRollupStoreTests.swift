@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeRollupStore = Labs.newMemoryReferenceRangeRollupStore()
        let item = Labs.newReferenceRangeRollup("code-311", label: "label-490")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
