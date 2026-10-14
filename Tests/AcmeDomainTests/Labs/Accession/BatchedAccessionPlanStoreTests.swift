@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryBatchedAccessionPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.BatchedAccessionPlanStore = Labs.newMemoryBatchedAccessionPlanStore()
        let item = Labs.newBatchedAccessionPlan("code-771", title: "title-890")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
