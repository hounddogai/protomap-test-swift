@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalRoundingTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalRoundingTemplateStore = ClinicalOps.newMemoryGlobalRoundingTemplateStore()
        let item = ClinicalOps.newGlobalRoundingTemplate("code-16", name: "name-717")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
