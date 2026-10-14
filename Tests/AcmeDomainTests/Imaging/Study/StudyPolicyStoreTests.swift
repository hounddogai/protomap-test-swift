@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyPolicyStore = Imaging.newMemoryStudyPolicyStore()
        let item = Imaging.newStudyPolicy("code-769", title: "title-930")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
