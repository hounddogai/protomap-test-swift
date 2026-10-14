@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultOutreachPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultOutreachPlanStore = CareManagement.newMemoryDefaultOutreachPlanStore()
        let item = CareManagement.newDefaultOutreachPlan("code-176", title: "title-680")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
