@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapMilestoneStore = CareManagement.newMemoryCareGapMilestoneStore()
        let item = CareManagement.newCareGapMilestone("code-859", name: "name-134")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
