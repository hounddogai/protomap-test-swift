@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultTemplateStore = Labs.newMemoryResultTemplateStore()
        let item = Labs.newResultTemplate("code-202", name: "name-467")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
