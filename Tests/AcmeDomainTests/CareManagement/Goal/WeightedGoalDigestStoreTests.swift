@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedGoalDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedGoalDigestStore = CareManagement.newMemoryWeightedGoalDigestStore()
        let item = CareManagement.newWeightedGoalDigest("code-535", name: "name-170")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
