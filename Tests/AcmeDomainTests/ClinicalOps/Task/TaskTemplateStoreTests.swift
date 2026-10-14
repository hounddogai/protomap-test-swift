@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskTemplateStore = ClinicalOps.newMemoryTaskTemplateStore()
        let item = ClinicalOps.newTaskTemplate("code-395", name: "name-523")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
