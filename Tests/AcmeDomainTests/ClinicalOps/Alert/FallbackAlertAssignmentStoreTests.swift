@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackAlertAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackAlertAssignmentStore = ClinicalOps.newMemoryFallbackAlertAssignmentStore()
        let item = ClinicalOps.newFallbackAlertAssignment("code-554", title: "title-254")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
