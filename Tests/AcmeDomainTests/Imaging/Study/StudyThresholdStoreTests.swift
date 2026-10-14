@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyThresholdStore = Imaging.newMemoryStudyThresholdStore()
        let item = Imaging.newStudyThreshold("code-610", name: "name-193")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
