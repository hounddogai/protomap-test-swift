@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultAssessmentEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultAssessmentEstimateStore = CareManagement.newMemoryDefaultAssessmentEstimateStore()
        let item = CareManagement.newDefaultAssessmentEstimate("code-795", title: "title-255")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
