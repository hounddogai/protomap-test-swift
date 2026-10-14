@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyAssessmentRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyAssessmentRollupStore = CareManagement.newMemoryLegacyAssessmentRollupStore()
        let item = CareManagement.newLegacyAssessmentRollup("code-130", label: "label-409")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
