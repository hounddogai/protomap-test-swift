@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictModalityTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictModalityTargetStore = Imaging.newMemoryStrictModalityTargetStore()
        let item = Imaging.newStrictModalityTarget("code-556", label: "label-991")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
