@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultTargetStore = Labs.newMemoryResultTargetStore()
        let item = Labs.newResultTarget("code-61", name: "name-229")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
