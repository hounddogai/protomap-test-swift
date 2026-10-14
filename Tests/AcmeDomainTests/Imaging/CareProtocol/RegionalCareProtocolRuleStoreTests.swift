@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalCareProtocolRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalCareProtocolRuleStore = Imaging.newMemoryRegionalCareProtocolRuleStore()
        let item = Imaging.newRegionalCareProtocolRule("code-754", label: "label-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
