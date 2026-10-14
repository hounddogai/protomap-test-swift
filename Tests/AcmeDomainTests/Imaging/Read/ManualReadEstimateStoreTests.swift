@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualReadEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualReadEstimateStore = Imaging.newMemoryManualReadEstimateStore()
        let item = Imaging.newManualReadEstimate("code-132", title: "title-721")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
