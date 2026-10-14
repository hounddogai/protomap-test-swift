@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelPolicyStore = Labs.newMemoryPanelPolicyStore()
        let item = Labs.newPanelPolicy("code-719", title: "title-559")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
