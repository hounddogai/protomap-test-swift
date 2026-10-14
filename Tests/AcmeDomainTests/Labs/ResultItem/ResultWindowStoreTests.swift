@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultWindowStore = Labs.newMemoryResultWindowStore()
        let item = Labs.newResultWindow("code-789", title: "title-544")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
