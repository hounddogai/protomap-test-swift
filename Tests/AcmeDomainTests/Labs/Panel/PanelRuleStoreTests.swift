@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelRuleStore = Labs.newMemoryPanelRuleStore()
        let item = Labs.newPanelRule("code-382", name: "name-51")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
