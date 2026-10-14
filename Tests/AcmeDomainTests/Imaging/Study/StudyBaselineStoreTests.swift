@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyBaselineStore = Imaging.newMemoryStudyBaselineStore()
        let item = Imaging.newStudyBaseline("code-524", label: "label-651")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
