@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffProfileStore = ClinicalOps.newMemoryHandoffProfileStore()
        let item = ClinicalOps.newHandoffProfile("code-338", label: "label-243")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
