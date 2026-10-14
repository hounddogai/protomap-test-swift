@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalOrderSetTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalOrderSetTemplateStore = ClinicalOps.newMemorySeasonalOrderSetTemplateStore()
        let item = ClinicalOps.newSeasonalOrderSetTemplate("code-171", label: "label-755")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
