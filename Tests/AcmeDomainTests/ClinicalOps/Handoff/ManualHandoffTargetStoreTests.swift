@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryManualHandoffTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ManualHandoffTargetStore = ClinicalOps.newMemoryManualHandoffTargetStore()
        let item = ClinicalOps.newManualHandoffTarget("code-953", name: "name-209")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
