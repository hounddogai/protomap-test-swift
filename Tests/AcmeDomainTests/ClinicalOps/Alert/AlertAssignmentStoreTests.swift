@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertAssignmentStore = ClinicalOps.newMemoryAlertAssignmentStore()
        let item = ClinicalOps.newAlertAssignment("code-28", title: "title-782")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
