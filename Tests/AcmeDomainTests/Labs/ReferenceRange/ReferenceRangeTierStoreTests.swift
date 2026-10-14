@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeTierStore = Labs.newMemoryReferenceRangeTierStore()
        let item = Labs.newReferenceRangeTier("code-323", label: "label-32")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
