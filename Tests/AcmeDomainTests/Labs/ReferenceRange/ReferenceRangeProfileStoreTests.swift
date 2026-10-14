@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeProfileStore = Labs.newMemoryReferenceRangeProfileStore()
        let item = Labs.newReferenceRangeProfile("code-172", name: "name-88")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
