@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeWindowStore = Labs.newMemoryReferenceRangeWindowStore()
        let item = Labs.newReferenceRangeWindow("code-34", title: "title-617")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
