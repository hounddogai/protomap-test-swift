@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalModalityCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalModalityCycleStore = Imaging.newMemoryGlobalModalityCycleStore()
        let item = Imaging.newGlobalModalityCycle("code-805", label: "label-478")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
