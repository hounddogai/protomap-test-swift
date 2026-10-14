@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedCourierRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedCourierRollupStore = Labs.newMemoryCappedCourierRollupStore()
        let item = Labs.newCappedCourierRollup("code-134", name: "name-511")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
