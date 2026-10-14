@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryBatchedReadPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.BatchedReadPlanStore = Imaging.newMemoryBatchedReadPlanStore()
        let item = Imaging.newBatchedReadPlan("code-472", label: "label-930")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
