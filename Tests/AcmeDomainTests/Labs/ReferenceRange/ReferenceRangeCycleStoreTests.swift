@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeCycleStore = Labs.newMemoryReferenceRangeCycleStore()
        let item = Labs.newReferenceRangeCycle("code-153", label: "label-779")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
