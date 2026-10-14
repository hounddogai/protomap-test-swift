@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultBundleStore = Labs.newMemoryResultBundleStore()
        let item = Labs.newResultBundle("code-482", title: "title-635")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
