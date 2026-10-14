@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreTierStore = CareManagement.newMemoryRiskScoreTierStore()
        let item = CareManagement.newRiskScoreTier("code-268", label: "label-263")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
