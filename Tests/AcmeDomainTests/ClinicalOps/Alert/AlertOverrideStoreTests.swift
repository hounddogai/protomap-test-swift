@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertOverrideStore = ClinicalOps.newMemoryAlertOverrideStore()
        let item = ClinicalOps.newAlertOverride("code-73", title: "title-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
