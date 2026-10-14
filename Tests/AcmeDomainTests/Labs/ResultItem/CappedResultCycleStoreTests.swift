@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedResultCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedResultCycleStore = Labs.newMemoryCappedResultCycleStore()
        let item = Labs.newCappedResultCycle("code-207", label: "label-532")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
