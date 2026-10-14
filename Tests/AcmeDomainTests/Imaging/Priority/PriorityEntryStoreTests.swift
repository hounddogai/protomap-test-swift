@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityEntryStore = Imaging.newMemoryPriorityEntryStore()
        let item = Imaging.newPriorityEntry("code-699", name: "name-913")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
