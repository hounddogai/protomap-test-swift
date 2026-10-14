@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityCycleStore = Imaging.newMemoryModalityCycleStore()
        let item = Imaging.newModalityCycle("code-42", label: "label-110")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
