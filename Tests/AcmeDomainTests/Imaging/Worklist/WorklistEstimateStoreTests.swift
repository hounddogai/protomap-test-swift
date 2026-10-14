@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistEstimateStore = Imaging.newMemoryWorklistEstimateStore()
        let item = Imaging.newWorklistEstimate("code-251", name: "name-182")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
