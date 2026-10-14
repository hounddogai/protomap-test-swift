@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalStudyRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalStudyRuleStore = Imaging.newMemoryRegionalStudyRuleStore()
        let item = Imaging.newRegionalStudyRule("code-877", title: "title-332")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
