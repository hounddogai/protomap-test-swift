@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedRiskScoreManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedRiskScoreManifestStore = CareManagement.newMemoryWeightedRiskScoreManifestStore()
        let item = CareManagement.newWeightedRiskScoreManifest("code-840", label: "label-542")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
