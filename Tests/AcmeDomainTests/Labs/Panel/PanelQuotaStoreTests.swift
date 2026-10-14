@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelQuotaStore = Labs.newMemoryPanelQuotaStore()
        let item = Labs.newPanelQuota("code-896", title: "title-768")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
