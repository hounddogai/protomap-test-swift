@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentDigestStore = CareManagement.newMemoryAssessmentDigestStore()
        let item = CareManagement.newAssessmentDigest("code-757", label: "label-315")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
