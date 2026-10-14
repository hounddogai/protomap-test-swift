@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedCareGapDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedCareGapDraftStore = CareManagement.newMemoryWeightedCareGapDraftStore()
        let item = CareManagement.newWeightedCareGapDraft("code-108", title: "title-709")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
