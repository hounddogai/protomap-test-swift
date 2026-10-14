@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadTemplateStore = Imaging.newMemoryReadTemplateStore()
        let item = Imaging.newReadTemplate("code-167", label: "label-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
