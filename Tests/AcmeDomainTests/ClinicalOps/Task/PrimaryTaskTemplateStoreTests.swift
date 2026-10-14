@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryTaskTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryTaskTemplateStore = ClinicalOps.newMemoryPrimaryTaskTemplateStore()
        let item = ClinicalOps.newPrimaryTaskTemplate("code-486", name: "name-114")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
