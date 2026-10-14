@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentThresholdStore = CareManagement.newMemoryAssessmentThresholdStore()
        let item = CareManagement.newAssessmentThreshold("code-320", label: "label-899")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
