@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentMappingStore = CareManagement.newMemoryAssessmentMappingStore()
        let item = CareManagement.newAssessmentMapping("code-447", name: "name-906")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
