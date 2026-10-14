@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualRiskScoreGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualRiskScoreGroupStore = CareManagement.newMemoryManualRiskScoreGroupStore()
        let item = CareManagement.newManualRiskScoreGroup("code-881", label: "label-293")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
