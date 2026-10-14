@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultOverrideStore = Labs.newMemoryResultOverrideStore()
        let item = Labs.newResultOverride("code-87", label: "label-57")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
