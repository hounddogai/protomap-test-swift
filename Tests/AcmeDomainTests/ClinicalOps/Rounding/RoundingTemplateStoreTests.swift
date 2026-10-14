@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingTemplateStore = ClinicalOps.newMemoryRoundingTemplateStore()
        let item = ClinicalOps.newRoundingTemplate("code-408", name: "name-287")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
