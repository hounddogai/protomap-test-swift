@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalPriorityRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalPriorityRuleStore = Imaging.newMemorySeasonalPriorityRuleStore()
        let item = Imaging.newSeasonalPriorityRule("code-810", label: "label-373")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
