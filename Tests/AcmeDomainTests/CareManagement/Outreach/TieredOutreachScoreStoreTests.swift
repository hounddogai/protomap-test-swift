@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredOutreachScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredOutreachScoreStore = CareManagement.newMemoryTieredOutreachScoreStore()
        let item = CareManagement.newTieredOutreachScore("code-443", name: "name-394")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
