@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalPanelTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalPanelTemplateStore = Labs.newMemoryGlobalPanelTemplateStore()
        let item = Labs.newGlobalPanelTemplate("code-766", label: "label-841")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
