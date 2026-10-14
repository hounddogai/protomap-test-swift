@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachPlanStore = CareManagement.newMemoryOutreachPlanStore()
        let item = CareManagement.newOutreachPlan("code-817", name: "name-975")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
