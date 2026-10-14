@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyVarianceStore = Imaging.newMemoryStudyVarianceStore()
        let item = Imaging.newStudyVariance("code-666", title: "title-711")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
