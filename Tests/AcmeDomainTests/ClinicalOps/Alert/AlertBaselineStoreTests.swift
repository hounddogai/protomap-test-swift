@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertBaselineStore = ClinicalOps.newMemoryAlertBaselineStore()
        let item = ClinicalOps.newAlertBaseline("code-486", title: "title-753")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
