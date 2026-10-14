@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredRiskScoreEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredRiskScoreEntryStore = CareManagement.newMemoryTieredRiskScoreEntryStore()
        let item = CareManagement.newTieredRiskScoreEntry("code-490", name: "name-618")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
