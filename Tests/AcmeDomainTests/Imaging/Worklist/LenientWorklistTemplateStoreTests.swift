@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientWorklistTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientWorklistTemplateStore = Imaging.newMemoryLenientWorklistTemplateStore()
        let item = Imaging.newLenientWorklistTemplate("code-882", label: "label-821")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
