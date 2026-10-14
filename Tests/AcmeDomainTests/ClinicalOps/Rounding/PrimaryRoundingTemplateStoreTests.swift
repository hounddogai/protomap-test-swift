@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryRoundingTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryRoundingTemplateStore = ClinicalOps.newMemoryPrimaryRoundingTemplateStore()
        let item = ClinicalOps.newPrimaryRoundingTemplate("code-926", title: "title-997")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
