@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryManualResultBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ManualResultBaselineStore = Labs.newMemoryManualResultBaselineStore()
        let item = Labs.newManualResultBaseline("code-143", name: "name-248")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
