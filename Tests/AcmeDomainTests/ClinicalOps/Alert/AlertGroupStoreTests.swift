@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertGroupStore = ClinicalOps.newMemoryAlertGroupStore()
        let item = ClinicalOps.newAlertGroup("code-378", label: "label-512")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
