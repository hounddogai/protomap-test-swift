@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingAssessmentSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingAssessmentSegmentStore = CareManagement.newMemoryPendingAssessmentSegmentStore()
        let item = CareManagement.newPendingAssessmentSegment("code-160", name: "name-320")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
