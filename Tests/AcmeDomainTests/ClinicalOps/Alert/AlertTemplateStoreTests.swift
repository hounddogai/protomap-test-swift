@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertTemplateStore = ClinicalOps.newMemoryAlertTemplateStore()
        let item = ClinicalOps.newAlertTemplate("code-676", name: "name-341")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
