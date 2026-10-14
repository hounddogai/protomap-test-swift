@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingWorklistEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingWorklistEstimateStore = Imaging.newMemoryPendingWorklistEstimateStore()
        let item = Imaging.newPendingWorklistEstimate("code-758", name: "name-859")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
