@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultProfileStore = Labs.newMemoryResultProfileStore()
        let item = Labs.newResultProfile("code-583", label: "label-274")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
