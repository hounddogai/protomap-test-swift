@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedPanelWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedPanelWindowStore = Labs.newMemoryCappedPanelWindowStore()
        let item = Labs.newCappedPanelWindow("code-439", title: "title-244")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
