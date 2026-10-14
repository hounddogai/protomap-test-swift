@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledStudyRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledStudyRuleStore = Imaging.newMemoryScheduledStudyRuleStore()
        let item = Imaging.newScheduledStudyRule("code-135", title: "title-567")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
