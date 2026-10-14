@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedRiskScoreTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedRiskScoreTemplateStore = CareManagement.newMemoryWeightedRiskScoreTemplateStore()
        let item = CareManagement.newWeightedRiskScoreTemplate("code-875", name: "name-2")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
