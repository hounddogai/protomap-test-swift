@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientStudyTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientStudyTargetStore = Imaging.newMemoryLenientStudyTargetStore()
        let item = Imaging.newLenientStudyTarget("code-835", name: "name-888")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
