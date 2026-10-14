@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientGoalVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientGoalVarianceStore = CareManagement.newMemoryLenientGoalVarianceStore()
        let item = CareManagement.newLenientGoalVariance("code-908", name: "name-693")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
