@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultRiskScoreGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultRiskScoreGroupStore = CareManagement.newMemoryDefaultRiskScoreGroupStore()
        let item = CareManagement.newDefaultRiskScoreGroup("code-759", label: "label-796")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
