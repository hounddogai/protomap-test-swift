@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultBaselineStore = Labs.newMemoryResultBaselineStore()
        let item = Labs.newResultBaseline("code-609", title: "title-805")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
