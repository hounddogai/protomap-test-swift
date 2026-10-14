@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictCareProtocolTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictCareProtocolTemplateStore = Imaging.newMemoryStrictCareProtocolTemplateStore()
        let item = Imaging.newStrictCareProtocolTemplate("code-213", label: "label-534")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
