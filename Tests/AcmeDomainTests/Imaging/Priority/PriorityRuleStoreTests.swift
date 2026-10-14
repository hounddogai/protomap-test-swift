@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityRuleStore = Imaging.newMemoryPriorityRuleStore()
        let item = Imaging.newPriorityRule("code-935", label: "label-281")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
