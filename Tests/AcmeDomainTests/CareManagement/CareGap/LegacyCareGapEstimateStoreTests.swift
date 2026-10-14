@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyCareGapEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyCareGapEstimateStore = CareManagement.newMemoryLegacyCareGapEstimateStore()
        let item = CareManagement.newLegacyCareGapEstimate("code-677", name: "name-281")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
