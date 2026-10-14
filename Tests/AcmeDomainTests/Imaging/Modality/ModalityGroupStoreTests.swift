@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityGroupStore = Imaging.newMemoryModalityGroupStore()
        let item = Imaging.newModalityGroup("code-873", label: "label-637")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
