@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalCareGapAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalCareGapAssignmentStore = CareManagement.newMemorySeasonalCareGapAssignmentStore()
        let item = CareManagement.newSeasonalCareGapAssignment("code-86", name: "name-463")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
