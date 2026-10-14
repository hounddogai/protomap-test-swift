@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualPriorityEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualPriorityEntryStore = Imaging.newMemoryManualPriorityEntryStore()
        let item = Imaging.newManualPriorityEntry("code-788", label: "label-234")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
