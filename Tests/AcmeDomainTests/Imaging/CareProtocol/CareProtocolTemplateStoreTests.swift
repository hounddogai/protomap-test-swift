@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolTemplateStore = Imaging.newMemoryCareProtocolTemplateStore()
        let item = Imaging.newCareProtocolTemplate("code-317", label: "label-907")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
