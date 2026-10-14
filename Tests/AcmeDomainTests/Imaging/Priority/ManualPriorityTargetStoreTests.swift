@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualPriorityTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualPriorityTargetStore = Imaging.newMemoryManualPriorityTargetStore()
        let item = Imaging.newManualPriorityTarget("code-296", label: "label-372")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
