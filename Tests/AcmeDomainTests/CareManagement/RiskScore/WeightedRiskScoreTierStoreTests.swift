@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedRiskScoreTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedRiskScoreTierStore = CareManagement.newMemoryWeightedRiskScoreTierStore()
        let item = CareManagement.newWeightedRiskScoreTier("code-613", name: "name-24")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
