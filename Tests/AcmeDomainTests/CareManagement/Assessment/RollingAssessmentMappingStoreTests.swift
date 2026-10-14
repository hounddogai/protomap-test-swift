@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingAssessmentMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingAssessmentMappingStore = CareManagement.newMemoryRollingAssessmentMappingStore()
        let item = CareManagement.newRollingAssessmentMapping("code-126", name: "name-402")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
