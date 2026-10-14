@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistRuleStore = Imaging.newMemoryWorklistRuleStore()
        let item = Imaging.newWorklistRule("code-193", name: "name-612")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
