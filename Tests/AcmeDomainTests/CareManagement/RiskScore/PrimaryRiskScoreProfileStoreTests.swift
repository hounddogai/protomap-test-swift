@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryRiskScoreProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryRiskScoreProfileStore = CareManagement.newMemoryPrimaryRiskScoreProfileStore()
        let item = CareManagement.newPrimaryRiskScoreProfile("code-50", title: "title-95")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
