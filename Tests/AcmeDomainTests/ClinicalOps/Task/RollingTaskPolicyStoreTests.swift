@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingTaskPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingTaskPolicyStore = ClinicalOps.newMemoryRollingTaskPolicyStore()
        let item = ClinicalOps.newRollingTaskPolicy("code-480", label: "label-874")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
