@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedCareGapClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedCareGapClaimStore = CareManagement.newMemoryWeightedCareGapClaimStore()
        let item = CareManagement.newWeightedCareGapClaim("code-499", label: "label-456")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
