@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskTargetStore = ClinicalOps.newMemoryTaskTargetStore()
        let item = ClinicalOps.newTaskTarget("code-628", label: "label-160")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
