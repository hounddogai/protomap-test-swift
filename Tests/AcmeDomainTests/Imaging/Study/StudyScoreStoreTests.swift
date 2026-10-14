@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyScoreStore = Imaging.newMemoryStudyScoreStore()
        let item = Imaging.newStudyScore("code-347", title: "title-386")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
