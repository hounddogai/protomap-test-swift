@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredOutreachPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredOutreachPlanStore = CareManagement.newMemoryTieredOutreachPlanStore()
        let item = CareManagement.newTieredOutreachPlan("code-424", label: "label-686")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
