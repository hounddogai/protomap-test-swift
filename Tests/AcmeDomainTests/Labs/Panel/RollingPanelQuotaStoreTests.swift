@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingPanelQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingPanelQuotaStore = Labs.newMemoryRollingPanelQuotaStore()
        let item = Labs.newRollingPanelQuota("code-262", title: "title-463")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
