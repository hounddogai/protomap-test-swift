@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityGroupStore = Imaging.newMemoryPriorityGroupStore()
        let item = Imaging.newPriorityGroup("code-201", label: "label-439")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
