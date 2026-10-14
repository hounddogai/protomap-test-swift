@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertSegmentStore = ClinicalOps.newMemoryAlertSegmentStore()
        let item = ClinicalOps.newAlertSegment("code-894", label: "label-249")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
