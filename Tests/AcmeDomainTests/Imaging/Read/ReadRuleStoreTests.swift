@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadRuleStore = Imaging.newMemoryReadRuleStore()
        let item = Imaging.newReadRule("code-388", name: "name-817")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
