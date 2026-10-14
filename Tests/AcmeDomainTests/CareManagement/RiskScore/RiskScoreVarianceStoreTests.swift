@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreVarianceStore = CareManagement.newMemoryRiskScoreVarianceStore()
        let item = CareManagement.newRiskScoreVariance("code-906", name: "name-885")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
