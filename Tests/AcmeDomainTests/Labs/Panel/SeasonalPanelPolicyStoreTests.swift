@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalPanelPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalPanelPolicyStore = Labs.newMemorySeasonalPanelPolicyStore()
        let item = Labs.newSeasonalPanelPolicy("code-601", name: "name-582")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
