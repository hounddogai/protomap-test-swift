@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionRollupStore = Labs.newMemoryAccessionRollupStore()
        let item = Labs.newAccessionRollup("code-550", name: "name-838")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
