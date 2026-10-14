@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyRuleStore = Imaging.newMemoryStudyRuleStore()
        let item = Imaging.newStudyRule("code-802", name: "name-36")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
