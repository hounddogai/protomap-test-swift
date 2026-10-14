@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedProgramRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedProgramRollupStore = CareManagement.newMemoryWeightedProgramRollupStore()
        let item = CareManagement.newWeightedProgramRollup("code-216", label: "label-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
