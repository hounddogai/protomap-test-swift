@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveAssessmentThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveAssessmentThresholdStore = CareManagement.newMemoryAdaptiveAssessmentThresholdStore()
        let item = CareManagement.newAdaptiveAssessmentThreshold("code-985", title: "title-955")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
