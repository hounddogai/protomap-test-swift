@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualPriorityRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualPriorityRuleStore = Imaging.newMemoryManualPriorityRuleStore()
        let item = Imaging.newManualPriorityRule("code-87", title: "title-76")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
