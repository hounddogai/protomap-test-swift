@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictAlertCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictAlertCheckpointStore = ClinicalOps.newMemoryStrictAlertCheckpointStore()
        let item = ClinicalOps.newStrictAlertCheckpoint("code-995", name: "name-343")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
