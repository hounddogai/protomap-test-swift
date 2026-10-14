@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityTargetStore = Imaging.newMemoryPriorityTargetStore()
        let item = Imaging.newPriorityTarget("code-638", label: "label-518")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
