@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveRiskScoreItemStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveRiskScoreItemStore = CareManagement.newMemoryAdaptiveRiskScoreItemStore()
        let item = CareManagement.newAdaptiveRiskScoreItem("code-860", name: "name-803")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
