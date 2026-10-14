@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultRequestStore = Labs.newMemoryResultRequestStore()
        let item = Labs.newResultRequest("code-734", title: "title-877")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
